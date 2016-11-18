require 'bigcommerce_connection.rb'
require 'clean_data.rb'

class Order < ActiveRecord::Base

	include CleanData
	belongs_to :customer
	delegate :staff, to: :customer, allow_nil: true
	belongs_to :status
	belongs_to :coupon
	belongs_to :staff
	has_many :order_shippings
	has_many :addresses, through: :order_shippings
	belongs_to :billing_address, class_name: :Address, foreign_key: :billing_address_id
	has_many :order_products
	has_many :products, through: :order_products
	#has_many :products, through: :order_products

	belongs_to :order_history
	belongs_to :xero_invoice

	self.per_page = 30


	def scrape

		order_api = Bigcommerce::Order
		order_count = order_api.count.count
		limit = 50 
		order_pages = (order_count/limit) + 1
		
		page_number = 1

		order_product = OrderProduct.new
		
		order_pages.times do

			orders = order_api.all(page: page_number)

			orders.each do |o|
				
				insert_or_update(o, 1)
				order_product.insert(o.id)

			end

			page_number += 1

		end

	end

	def update_from_api(update_time)

		order_api = Bigcommerce::Order

		order_count = order_api.count(min_date_modified: update_time).count
		limit = 50
		order_pages = (order_count/limit) + 1
		order_product = OrderProduct.new

		page_number = 1

		order_pages.times do

			orders = order_api.all(min_date_modified: update_time, page: page_number)
			
			if orders.blank?
				return
			end

			orders.each do |o|
				if !Order.where(id: o.id).blank?
					#move row to history, update this one

					# Insert into Order History tables
					#last_insert_id = OrderHistory.new.insert(o.id)
					#OrderProductHistory.new.insert(last_insert_id, o.id)

					# Update Order Table
					insert_or_update(o, 0)
					

				    # doing a delete - insert instead of a select - update
				    # because select - update doesnt work when product gets deleted

				    # Update Order Product table
				    order_product.delete(o.id)
				    order_product.insert(o.id)

				else
					#insert a new one
					insert_or_update(o, 1)
					order_product.insert(o.id)
				end

			end

			page_number += 1
		end

	end

	def insert_or_update(o, insert)

		order = sql = ""
		time = Time.now.to_s(:db)

		date_created = map_date(o.date_created)
		date_modified = map_date(o.date_modified)
		date_shipped = map_date(o.date_shipped)

		staff_notes = remove_apostrophe(o.staff_notes)

		customer_notes = remove_apostrophe(o.customer_message)

		active = convert_bool(o.is_deleted)

		payment_method = remove_apostrophe(o.payment_method)

		if insert == 1

			order = "('#{o.id}', '#{o.customer_id}', '#{date_created}', '#{date_modified}',\
			'#{date_shipped}', '#{o.status_id}', '#{o.subtotal_ex_tax}', '#{o.subtotal_inc_tax}',\
			'#{o.subtotal_tax}', '#{o.base_shipping_cost}', '#{o.shipping_cost_ex_tax}', '#{o.shipping_cost_inc_tax}',\
			'#{o.shipping_cost_tax}', '#{o.shipping_cost_tax_class_id}', '#{o.base_handling_cost}',\
			'#{o.handling_cost_ex_tax}', '#{o.handling_cost_inc_tax}', '#{o.handling_cost_tax}',\
			'#{o.handling_cost_tax_class_id}', '#{o.base_wrapping_cost}', '#{o.wrapping_cost_ex_tax}',\
			'#{o.wrapping_cost_inc_tax}', '#{o.wrapping_cost_tax}', '#{o.wrapping_cost_tax_class_id}',\
			'#{o.total_ex_tax}', '#{o.total_inc_tax}', '#{o.total_tax}', '#{o.items_total}', '#{o.items_shipped}',\
			'#{o.refunded_amount}', '#{o.store_credit_amount}', '#{o.gift_certificate_amount}',\
			'#{o.ip_address}', '#{staff_notes}', '#{customer_notes}',\
			'#{o.discount_amount}', '#{o.coupon_discount}', '#{active}', '#{o.order_source}', '#{time}', '#{time}', '#{payment_method}')"

			
			sql = "INSERT INTO orders (id, customer_id, date_created, date_modified, date_shipped,\
			status_id, subtotal_ex_tax, subtotal_inc_tax, subtotal_tax, base_shipping_cost,\
			shipping_cost_ex_tax, shipping_cost_inc_tax, shipping_cost_tax, shipping_cost_tax_class_id,\
			base_handling_cost, handling_cost_ex_tax, handling_cost_inc_tax, handling_cost_tax, handling_cost_tax_class_id,\
			base_wrapping_cost, wrapping_cost_ex_tax, wrapping_cost_inc_tax, wrapping_cost_tax, wrapping_cost_tax_class_id,\
			total_ex_tax, total_inc_tax, total_tax, qty, items_shipped, refunded_amount, store_credit,\
			gift_certificate_amount, ip_address, staff_notes, customer_notes, discount_amount,\
			coupon_discount, active, order_source, created_at, updated_at, payment_method)\
			VALUES #{order}"

		else
			sql = "UPDATE orders SET customer_id = '#{o.customer_id}', date_created = '#{date_created}',\
					date_modified = '#{date_modified}', date_shipped = '#{date_shipped}', status_id = '#{o.status_id}',\
					subtotal_ex_tax = '#{o.subtotal_ex_tax}', subtotal_inc_tax = '#{o.subtotal_inc_tax}', subtotal_tax = '#{o.subtotal_tax}', base_shipping_cost = '#{o.base_shipping_cost}',\
					shipping_cost_ex_tax = '#{o.shipping_cost_ex_tax}', shipping_cost_inc_tax = '#{o.shipping_cost_inc_tax}', shipping_cost_tax = '#{o.shipping_cost_tax}',\
					shipping_cost_tax_class_id = '#{o.shipping_cost_tax_class_id}', base_handling_cost = '#{o.base_handling_cost}', handling_cost_ex_tax = '#{o.handling_cost_ex_tax}',\
					handling_cost_inc_tax = '#{o.handling_cost_inc_tax}', handling_cost_tax = '#{o.handling_cost_tax}', handling_cost_tax_class_id = '#{o.handling_cost_tax_class_id}',\
					total_ex_tax = '#{o.total_ex_tax}', total_inc_tax = '#{o.total_inc_tax}', total_tax = '#{o.total_tax}', qty = '#{o.items_total}', items_shipped = '#{o.items_shipped}',\
					refunded_amount = '#{o.refunded_amount}', store_credit = '#{o.store_credit_amount}', gift_certificate_amount = '#{o.gift_certificate_amount}',\
					ip_address = '#{o.ip_address}', staff_notes = '#{staff_notes}', customer_notes = '#{customer_notes}', discount_amount = '#{o.discount_amount}',\
					coupon_discount = '#{o.coupon_discount}', active = '#{active}', order_source = '#{o.order_source}', updated_at = '#{time}', payment_method = '#{payment_method}' WHERE id = '#{o.id}'"

		end
		ActiveRecord::Base.connection.execute(sql)

	end

	def self.order_filter(order_id)
		return find(order_id.to_i) if order_id.to_i > 0
		return all
	end

	def self.order_filter_by_ids(order_ids)
		return where('orders.id IN (?)', order_ids).references(:orders)
	end

	def self.product_filter(product_ids)
		return includes(:order_products).where('order_products.product_id IN (?)', product_ids).references(:order_products) if !product_ids.nil?
		return all
	end

	# Returns orders whose date created is between the start date and end date
	# If you want today's orders
	# Then start date should be Today's date and end date should be Tomorrow's date
	# Since date_created is stored as datetime in the database, these start and end dates are
	# converted into datetime values, with 00:00:00 as the time factor.
	def self.date_filter(start_date, end_date)
		if (!start_date.nil? && !end_date.nil?)
			if !start_date.to_s.empty? && !end_date.to_s.empty?
			  start_time = Time.parse(start_date.to_s)
	          end_time = Time.parse(end_date.to_s)

			  return where('orders.date_created >= ? and orders.date_created <= ?', start_time.strftime("%Y-%m-%d %H:%M:%S"), end_time.strftime("%Y-%m-%d %H:%M:%S"))
			end
		end
		return all
	end

	# Returns Orders who status has a valid order flag
	def self.valid_order
		includes(:status).where('statuses.valid_order = 1').references(:statuses)
	end

	# Returns orders with a given status id
	def self.status_filter(status_id)
		return where(status_id: status_id) if !status_id.nil?
		return all
	end

	def self.group_by_date_created
		group("DATE(orders.date_created)")
	end

	def self.group_by_week_created
		group("WEEK(orders.date_created)")
	end

	def self.group_by_month_created
		group(["MONTH(orders.date_created)", "YEAR(orders.date_created)"])
	end

	def self.group_by_quarter_created
		group(["QUARTER(orders.date_created)", "YEAR(orders.date_created)"])
	end

	def self.group_by_date_created_and_staff_id
		includes(:customer).group(["customers.staff_id", "DATE(orders.date_created)"])
	end

	def self.group_by_week_created_and_staff_id
		includes(:customer).group(["customers.staff_id", "WEEK(orders.date_created)"])
	end

	def self.group_by_month_created_and_staff_id
		includes(:customer).group(["customers.staff_id", "MONTH(orders.date_created)", "YEAR(orders.date_created)"])
	end

	def self.group_by_quarter_created_and_staff_id
		includes(:customer).group(["customers.staff_id", "QUARTER(orders.date_created)", "YEAR(orders.date_created)"])
	end

	def self.group_by_customerid
		group('orders.customer_id')
	end

	def self.group_by_product_id
		includes(:order_products).group('order_products.product_id')
	end

	def self.count_order_id_from_order_products
		includes(:order_products).count('order_products.order_id')
	end

	def self.count_orders
		count('orders.id')
	end

	def self.sum_total
		sum('orders.total_inc_tax')
	end

	def self.sum_qty
		sum('orders.qty')
	end

	def self.avg_order_total
		average('orders.total_inc_tax')
	end

	def self.avg_order_qty
		average('orders.qty')
	end

	def self.avg_luc
		# TO DO 
	end

	def self.sum_order_product_qty
		includes(:order_products).sum('order_products.qty')
	end

	def self.customer_filter(customer_ids)
		return where('orders.customer_id IN (?)', customer_ids) unless (customer_ids.nil? or  customer_ids.empty?)
		return all
	end

	def self.staff_filter(staff_id)
		return includes(:customer).where('customers.staff_id = ?', staff_id).references(:customers) if !staff_id.nil?
		return all
	end

	def self.order_by_id
		order('orders.id DESC')
	end

	def self.include_all
		includes([{:customer => :staff}, :status, {:order_products => :product}, :xero_invoice])
	end

	def self.xero_invoice_id_is_null
		where(xero_invoice_id: nil)
	end

	def self.export_to_xero
		xero_invoice_id_is_null.include_all.where('statuses.xero_import = 1 and orders.total_inc_tax > 0').references(:statuses)
	end

	def self.insert_invoice(order_id, invoice_id)
		order = order_filter(order_id)
		order.xero_invoice_id = invoice_id
		order.xero_invoice_number = order_id
		order.save
	end

end
