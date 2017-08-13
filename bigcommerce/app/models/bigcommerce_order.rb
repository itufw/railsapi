require 'bigcommerce_connection.rb'
require 'clean_data.rb'

class BigcommerceOrder < ActiveRecord::Base
  include CleanData
  def scrape
    order_api = Bigcommerce::Order
    order_count = order_api.count.count
    limit = 50
    order_pages = (order_count / limit) + 1

    page_number = 1

    order_product = BigcommerceOrderProduct.new

    order_pages.times do
      orders = order_api.all(page: page_number)

      orders.each do |o|
        insert_or_update(o, 1)
        order_product.insert(o.id, nil)
      end

      page_number += 1
    end
  end

  def update_from_api(update_time)
    order_api = Bigcommerce::Order

    order_count = order_api.count(min_date_modified: update_time).count
    limit = 50
    order_pages = (order_count / limit) + 1
    order_product = BigcommerceOrderProduct.new

    page_number = 1

    order_pages.times do
      orders = order_api.all(min_date_modified: update_time, page: page_number)

      return if orders.blank?

      orders.each do |o|
        if !BigcommerceOrder.where(id: o.id).blank?
          # move row to history, update this one

          # Insert into Order History tables
          # last_insert_id = OrderHistory.new.insert(o.id)
          # OrderProductHistory.new.insert(last_insert_id, o.id)

          # Update Order Table
          # order from new order table
          order = insert_or_update(o, 0)

          # doing a delete - insert instead of a select - update
          # because select - update doesnt work when product gets deleted

          # Update Order Product table
          order_product.delete(o.id)
          order_product.insert(o.id)

        else
          # insert a new one
          order = insert_or_update(o, 1)
          order_product.insert(o.id)
        end
        Address.new.insert_or_update(o.billing_address, o.customer_id, o.id)
      end

      page_number += 1
    end
  end

  def insert_or_update(o, insert)
    order = sql = ''
    time = Time.now.to_s(:db)

    date_created = map_date(o.date_created)
    date_modified = map_date(o.date_modified)
    date_shipped = map_date(o.date_shipped)

    staff_notes = remove_apostrophe(o.staff_notes)

    customer_notes = remove_apostrophe(o.customer_message)

    active = convert_bool(o.is_deleted)

    payment_method = remove_apostrophe(o.payment_method)

    if insert == 1
      staff_id = Customer.find(o.customer_id).staff_id

      order = "('#{o.id}', '#{o.customer_id}', '#{date_created}',\
      '#{date_modified}', '#{date_shipped}', '#{o.status_id}',\
      '#{o.subtotal_ex_tax}', '#{o.subtotal_inc_tax}', '#{o.subtotal_tax}',\
      '#{o.base_shipping_cost}', '#{o.shipping_cost_ex_tax}',\
      '#{o.shipping_cost_inc_tax}', '#{o.shipping_cost_tax}',\
      '#{o.shipping_cost_tax_class_id}', '#{o.base_handling_cost}',\
			'#{o.handling_cost_ex_tax}', '#{o.handling_cost_inc_tax}',\
      '#{o.handling_cost_tax}', '#{o.handling_cost_tax_class_id}',\
      '#{o.base_wrapping_cost}', '#{o.wrapping_cost_ex_tax}',\
  		'#{o.wrapping_cost_inc_tax}', '#{o.wrapping_cost_tax}',\
      '#{o.wrapping_cost_tax_class_id}', '#{o.total_ex_tax}',\
      '#{o.total_inc_tax}', '#{o.total_tax}', '#{o.items_total}',\
      '#{o.items_shipped}', '#{o.refunded_amount}', '#{o.store_credit_amount}',\
      '#{o.gift_certificate_amount}','#{o.ip_address}', '#{staff_notes}',\
      '#{customer_notes}', '#{o.discount_amount}', '#{o.coupon_discount}',\
      '#{active}', '#{o.order_source}', '#{time}', '#{time}',\
      '#{payment_method}', '#{staff_id}')"

      sql = "INSERT INTO bigcommerce_orders (id, customer_id, date_created, date_modified, date_shipped,\
			status_id, subtotal_ex_tax, subtotal_inc_tax, subtotal_tax, base_shipping_cost,\
			shipping_cost_ex_tax, shipping_cost_inc_tax, shipping_cost_tax, shipping_cost_tax_class_id,\
			base_handling_cost, handling_cost_ex_tax, handling_cost_inc_tax, handling_cost_tax, handling_cost_tax_class_id,\
			base_wrapping_cost, wrapping_cost_ex_tax, wrapping_cost_inc_tax, wrapping_cost_tax, wrapping_cost_tax_class_id,\
			total_ex_tax, total_inc_tax, total_tax, qty, items_shipped, refunded_amount, store_credit,\
			gift_certificate_amount, ip_address, staff_notes, customer_notes, discount_amount,\
			coupon_discount, active, order_source, created_at, updated_at, payment_method, staff_id)\
			VALUES #{order}"

      # insert the billing adress where the id is order_id
      Address.new.insert_or_update(o.billing_address, o.customer_id, o.id)

      order = Order.new.import_from_bigcommerce(o)
    else
      sql = "UPDATE bigcommerce_orders SET customer_id = '#{o.customer_id}', date_created = '#{date_created}',\
					date_modified = '#{date_modified}', date_shipped = '#{date_shipped}', status_id = '#{o.status_id}',\
					subtotal_ex_tax = '#{o.subtotal_ex_tax}', subtotal_inc_tax = '#{o.subtotal_inc_tax}', subtotal_tax = '#{o.subtotal_tax}', base_shipping_cost = '#{o.base_shipping_cost}',\
					shipping_cost_ex_tax = '#{o.shipping_cost_ex_tax}', shipping_cost_inc_tax = '#{o.shipping_cost_inc_tax}', shipping_cost_tax = '#{o.shipping_cost_tax}',\
					shipping_cost_tax_class_id = '#{o.shipping_cost_tax_class_id}', base_handling_cost = '#{o.base_handling_cost}', handling_cost_ex_tax = '#{o.handling_cost_ex_tax}',\
					handling_cost_inc_tax = '#{o.handling_cost_inc_tax}', handling_cost_tax = '#{o.handling_cost_tax}', handling_cost_tax_class_id = '#{o.handling_cost_tax_class_id}',\
					total_ex_tax = '#{o.total_ex_tax}', total_inc_tax = '#{o.total_inc_tax}', total_tax = '#{o.total_tax}', qty = '#{o.items_total}', items_shipped = '#{o.items_shipped}',\
					refunded_amount = '#{o.refunded_amount}', store_credit = '#{o.store_credit_amount}', gift_certificate_amount = '#{o.gift_certificate_amount}',\
					ip_address = '#{o.ip_address}', staff_notes = '#{staff_notes}', customer_notes = '#{customer_notes}', discount_amount = '#{o.discount_amount}',\
					coupon_discount = '#{o.coupon_discount}', active = '#{active}', updated_at = '#{time}', payment_method = '#{payment_method}' WHERE id = '#{o.id}'"

      # update order action table
      # if o.status_id == 10
      #   OrderAction.new.order_paid(o.id)
      # end
      order = Order.where("source = 'bigcommerce' AND source_id = ?", o.id).first
      order = order.update_from_bigcommerce(o)
    end
    ActiveRecord::Base.connection.execute(sql)
    order
  end
end
