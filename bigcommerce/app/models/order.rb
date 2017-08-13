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
  has_many :order_actions
  belongs_to :bigcommerce_address, class_name: :Address, foreign_key: :billing_address_id
  has_many :order_products
  has_many :products, through: :order_products
  has_many :order_histories
  # has_many :products, through: :order_products

  belongs_to :order_history
  belongs_to :xero_invoice

  after_validation :record_history, on: [:update, :delete], unless: ->(obj){ obj.xero_invoice_number_changed? or obj.xero_invoice_id_changed?}
  after_validation :cancel_order, on: [:update], if: ->(obj){ obj.status_id_changed? and obj.status_id == 5}


  self.per_page = 30

  def import_from_bigcommerce(order)
    customer = Customer.find(order.customer_id)
    params = {'customer_id': order.customer_id, 'status_id': 11, 'staff_id': customer.staff_id,\
       'total_inc_tax': order.total_inc_tax, 'qty': order.items_total, 'items_shipped': order.items_shipped,\
       'subtotal': order.subtotal_inc_tax.to_f/1.29, 'discount_rate': 0, 'discount_amount': order.discount_amount + order.coupon_discount,\
       'handling_cost': order.items_total.to_f * 1.82, 'shipping_cost': order.shipping_cost_ex_tax,\
       'wrapping_cost': order.wrapping_cost_ex_tax, 'wet': (order.subtotal_ex_tax.to_f - order.discount_amount.to_f - order.coupon_discount.to_f) * 0.29,\
       'gst': order.total_inc_tax.to_f / 11, 'staff_notes': remove_apostrophe(order.staff_notes),\
       'customer_notes': remove_apostrophe(order.customer_message), 'active': convert_bool(order.is_deleted),\
       'source': 'bigcommerce', 'source_id': order.id, 'date_created': map_date(order.date_created),\
       'date_shipped': map_date(order.date_shipped), 'created_by': 34, 'last_updated_by': 34,\
       'courier_status_id': 1, 'address': customer.address}
    self.update_attributes(params)
    self
  end

  def update_from_bigcommerce(order)
    customer = Customer.find(order.customer_id)
    params = {'customer_id': order.customer_id, 'status_id': 11, 'staff_id': customer.staff_id,\
       'total_inc_tax': order.total_inc_tax, 'qty': order.items_total, 'items_shipped': order.items_shipped,\
       'subtotal': order.subtotal_inc_tax.to_f/1.29, 'discount_rate': 0, 'discount_amount': order.discount_amount + order.coupon_discount,\
       'handling_cost': order.items_total.to_f * 1.82, 'shipping_cost': order.shipping_cost_ex_tax,\
       'wrapping_cost': order.wrapping_cost_ex_tax, 'wet': (order.subtotal_ex_tax.to_f - order.discount_amount.to_f - order.coupon_discount.to_f) * 0.29,\
       'gst': order.total_inc_tax.to_f / 11, 'staff_notes': remove_apostrophe(order.staff_notes),\
       'customer_notes': remove_apostrophe(order.customer_message), 'active': convert_bool(order.is_deleted),\
       'source': 'bigcommerce', 'source_id': order.id, 'date_created': map_date(order.date_created),\
       'date_shipped': map_date(order.date_shipped), 'created_by': 34, 'last_updated_by': 34,\
       'courier_status_id': 1, 'address': customer.address}
    self.update_attributes(params)
    self
  end

  ############## FILTER FUNCTIONS ############

  def self.order_filter(order_id)
    return find(order_id.to_i) if order_id.to_i > 0
    all
  end

  def self.order_filter_(order_id)
    return where(id: order_id.to_i) if order_id.to_i > 0
  end

  def self.order_filter_by_ids(order_ids)
    where('orders.id IN (?)', order_ids).references(:orders)
  end

  def self.product_filter(product_ids)
    # return includes(:order_products).where('order_products.product_id IN (?)', product_ids).references(:order_products) if !product_ids.nil?
    # return all
    return includes(:products).where('products.id IN (?)', product_ids).references(:products) unless product_ids.nil? || product_ids.empty?
    all
  end

  def self.order_product_filter(product_ids)
    # return includes(:order_products).where('order_products.product_id IN (?)', product_ids).references(:order_products) if !product_ids.nil?
    # return all
    includes(:order_products).where('order_products.product_id IN (?)', product_ids).references(:order_products)
  end

  def self.customer_filter(customer_ids)
    return where('orders.customer_id IN (?)', customer_ids) unless customer_ids.nil? || customer_ids.empty?
    all
  end

  def self.staff_filter(staff_id)
    return where(staff_id: staff_id) unless staff_id.nil?
    # return includes(:customer).where('customers.staff_id = ?', staff_id).references(:customers) unless staff_id.nil?
    all
  end

  def self.product_customer_filter(product_ids, customer_ids)
    return includes(:order_products).where('order_products.product_id IN (?)', product_ids).references(:order_products) if customer_ids.nil? || customer_ids.empty?
    includes(:order_products).where('order_products.product_id IN (?) OR orders.customer_id IN (?)', product_ids, customer_ids).references(:order_products)
  end

  # Returns orders whose date created is between the start date and end date
  # If you want today's orders
  # Then start date should be Today's date and end date should be Tomorrow's date
  # Since date_created is stored as datetime in the database, these start and end dates are
  # converted into datetime values, with 00:00:00 as the time factor.
  def self.date_filter(start_date, end_date)
    if !start_date.nil? && !end_date.nil?
      if !start_date.to_s.empty? && !end_date.to_s.empty?
        start_time = Time.parse(start_date.to_s)
        end_time = Time.parse(end_date.to_s)

        return where('orders.date_created >= ? and orders.date_created <= ?', start_time.strftime('%Y-%m-%d %H:%M:%S'), end_time.strftime('%Y-%m-%d %H:%M:%S'))
        end
    end
    all
  end

  # Returns Orders who status has a valid order flag
  def self.valid_order
    includes(:status).where('statuses.valid_order = 1').references(:statuses)
  end

  # Returns orders with a given status id
  def self.status_filter(status_id)
    return where('status_id = ?', status_id) unless status_id.nil?
    all
  end

  def self.statuses_filter(status_id)
    return where(status_id: status_id) unless status_id.nil? || status_id.blank?
    all
  end

  def self.cust_style_filter(cust_style_id)
    return includes(:customer).where('customers.cust_style_id = ?', cust_style_id).references(:customers) unless cust_style_id.nil?
    all
  end

  ########## GROUP BY FUNCTIONS ############

  def self.group_by_date_created
    group('DATE(orders.date_created)')
  end

  def self.group_by_week_created
    group('WEEK(orders.date_created)')
  end

  def self.group_by_month_created
    group(['MONTH(orders.date_created)', 'YEAR(orders.date_created)'])
  end

  def self.group_by_quarter_created
    group(['QUARTER(orders.date_created)', 'YEAR(orders.date_created)'])
  end

  def self.group_by_year_created
    group('YEAR(orders.date_created)')
  end

  def self.group_by_date_created_and_staff_id
    includes(:customer).group(['customers.staff_id', 'DATE(orders.date_created)'])
  end

  def self.group_by_week_created_and_staff_id
    includes(:customer).group(['customers.staff_id', 'WEEK(orders.date_created)'])
  end

  def self.group_by_month_created_and_staff_id
    includes(:customer).group(['customers.staff_id', 'MONTH(orders.date_created)', 'YEAR(orders.date_created)'])
  end

  def self.group_by_quarter_created_and_staff_id
    includes(:customer).group(['customers.staff_id', 'QUARTER(orders.date_created)', 'YEAR(orders.date_created)'])
  end

  def self.group_by_year_created_and_staff_id
    includes(:customer).group(['customers.staff_id', 'YEAR(orders.date_created)'])
  end

  # def self.group_by_week_created_and_product_id
  #     includes(:order_products).group(['order_products.product_id',\
  #                                      'WEEK(orders.date_created)']).references(:order_products)
  # end

  # def self.group_by_month_created_and_product_id
  #     includes(:order_products).group(['order_products.product_id',\
  #                                      'MONTH(orders.date_created)', 'YEAR(orders.date_created)']).references(:order_products)
  # end

  # def self.group_by_quarter_created_and_product_id
  #     includes(:order_products).group(['order_products.product_id',\
  #                                      'QUARTER(orders.date_created)', 'YEAR(orders.date_created)']).references(:order_products)
  # end

  def self.group_by_week_created_and_customer_id
    includes(:customer).group(['customers.id',\
                               'WEEK(orders.date_created)']).references(:customers)
 end

  def self.group_by_month_created_and_customer_id
    includes(:customer).group(['customers.id',\
                               'MONTH(orders.date_created)', 'YEAR(orders.date_created)']).references(:customers)
  end

  def self.group_by_quarter_created_and_customer_id
    includes(:customer).group(['customers.id',\
                               'QUARTER(orders.date_created)', 'YEAR(orders.date_created)']).references(:customers)
  end

  def self.group_by_year_created_and_customer_id
    includes(:customer).group(['customers.id',\
                               'YEAR(orders.date_created)']).references(:customers)
  end

  def self.group_by_customerid
    group('orders.customer_id')
  end

  def self.group_by_product_id
    includes(:order_products).group('order_products.product_id').references(:order_products)
  end

  # def self.group_by_product_no_vintage_id
  # 	includes(:products).group('products.product_no_vintage_id').references(:products)
  # end

  # def self.group_by_product_no_ws_id
  # 	includes(:products).group('products.product_no_ws_id').references(:products)
  # end

  ########## SUMMATION FUNCTIONS ############

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

  def self.avg_bottle_price
  end
  ######### ORDER BY FUNCTIONS ############

  def self.order_by_id(direction)
    order('orders.id ' + direction)
  end

  def self.order_by_customer(direction)
    includes(:customer).order('customers.actual_name ' + direction)
  end

  def self.order_by_staff(direction)
    includes(:staff).order('staffs.nickname ' + direction)
  end

  def self.order_by_status(direction)
    includes(:status).order('statuses.name ' + direction)
  end

  def self.order_by_qty(direction)
    order('qty ' + direction)
  end

  def self.order_by_total(direction)
    order('total_inc_tax ' + direction)
  end

  def self.order_by_date_created(direction)
    order('orders.date_created ' + direction)
  end

  def self.include_all
    includes([{ customer: :staff }, :status, { order_products: :product }, :xero_invoice])
  end

  # update_staff_id
  def update_staff_id
    self.staff_id = Customer.find(customer_id).staff_id
    save
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

  def self.total_dismatch
    includes(:xero_invoice).where('ROUND(orders.total_inc_tax, 1) <> Round(xero_invoices.total, 1)').references(:xero_invoice)
  end

  # return sample order and products
  def self.sample_orders
    where('orders.qty > 0 AND orders.total_inc_tax = 0')
  end

  # WHERE DO I USE THIS?
  def self.filter_by_product(product_ids)
    includes(:products).where('products.id IN (?)', [product_ids]).references(:products)
  end

  private

  def cancel_order
    order_products = self.order_products
    order_products.map(&:delete_product)
  end

  def record_history
    order_attributes =  "('#{self.id_was}', '#{self.customer_id_was}', '#{self.status_id_was}',\
    '#{self.courier_status_id_was}', '#{self.account_status_was}', '#{self.street_was}', '#{self.city_was}',\
    '#{self.state_was}', '#{self.postcode_was}', '#{self.country_was}', '#{self.address_was}',\
    '#{self.staff_id_was}', '#{self.total_inc_tax_was}', '#{self.qty_was}', '#{self.items_shipped_was}',\
    '#{self.subtotal_was}', '#{self.discount_rate_was}', '#{self.discount_amount_was}',\
    '#{self.handling_cost_was}', '#{self.shipping_cost_was}', '#{self.wrapping_cost_was}',\
    '#{self.wet_was}', '#{self.gst_was}',\
    '#{self.active_was}', '#{self.xero_invoice_id_was}', '#{self.xero_invoice_number_was}',\
    '#{self.source_was}', '#{self.source_id_was}', '#{self.date_created_was.to_s(:db)}',\
    '#{self.created_by_was}', '#{self.last_updated_by_was}', '#{self.created_at_was.to_s(:db)}', '#{self.updated_at_was.to_s(:db)}')"
    sql = "INSERT INTO order_histories(order_id, customer_id, status_id, courier_status_id,\
    account_status, street, city, state, postcode, country, address, staff_id,\
    total_inc_tax, qty, items_shipped, subtotal, discount_rate, discount_amount,\
    handling_cost, shipping_cost, wrapping_cost, wet, gst,\
    active, xero_invoice_id, xero_invoice_number, source, source_id, date_created,\
    created_by, last_updated_by, created_at, updated_at) VALUES #{order_attributes}"

    ActiveRecord::Base.connection.execute(sql)
  end
end
