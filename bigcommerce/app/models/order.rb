require 'clean_data.rb'
require 'bigcommerce_connection.rb'

class Order < ActiveRecord::Base
  include CleanData

  belongs_to :customer
  delegate :staff, to: :customer, allow_nil: true
  belongs_to :status
  belongs_to :courier_status
  belongs_to :coupon
  belongs_to :staff
  belongs_to :creator, foreign_key: 'created_by', class_name: 'Staff'
  belongs_to :updator, foreign_key: 'last_updated_by', class_name: 'Staff'
  has_many :order_shippings
  has_many :addresses, through: :order_shippings
  has_many :order_actions
  belongs_to :bigcommerce_address, class_name: :Address, foreign_key: :billing_address_id
  has_many :order_products
  has_many :products, through: :order_products
  has_many :order_histories
  # has_many :products, through: :order_products

  mount_uploader :proof_of_delivery, ProofOfDeliveryUploader

  belongs_to :order_history
  belongs_to :xero_invoice

  after_validation :record_history, on: [:update, :delete], unless: ->(obj){ obj.xero_invoice_number_changed? or obj.xero_invoice_id_changed? or !obj.total_inc_tax_changed?}
  after_validation :cancel_order, on: [:update], if: ->(obj){ obj.status_id_changed? and obj.status_id == 5}
  after_validation :recovery_order, on: [:update], if: ->(obj){ obj.status_id_changed? and obj.status_id_was == 5}
  after_validation :bigcommerce_status_update, on: [:update], if: ->(obj){obj.status_id_changed? and obj.source=='bigcommerce' and [2,3,4,5,6,7,8,9,10,11,12,13,26].include?obj.status_id and obj.last_updated_by!=34}
  after_validation :update_notes, on: [:update], if: ->(obj){obj.source=='bigcommerce' and (obj.staff_notes_changed? or obj.customer_notes_changed?)}
  after_validation :order_shipped, on: [:update], if: ->(obj){obj.status_id_changed? and obj.status_id==2}
  after_validation :order_completed, on: [:update], if: ->(obj){obj.status_id_changed? and obj.status_id==12}

  scoped_search on: [:id, :customer_purchase_order, :track_number], validator: ->(value){!value.nil?}

  self.per_page = 30

  def import_from_bigcommerce(order)
    customer = Customer.find(order.customer_id)
    status_id = Status.where('bigcommerce_id = ?', order.status_id).order('statuses.order').first.id
    params = {'id': order.id,'customer_id': order.customer_id,\
       'status_id': status_id, 'account_status': customer.account_approval(order.subtotal_inc_tax),\
       'staff_id': customer.staff_id, 'total_inc_tax': order.total_inc_tax,\
       'qty': order.items_total, 'items_shipped': order.items_shipped,\
       'subtotal': order.subtotal_inc_tax.to_f/1.1 + order.discount_amount.to_f + order.coupon_discount.to_f,\
       'discount_rate': 0, 'discount_amount': order.discount_amount.to_f + order.coupon_discount.to_f,\
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
    if order.status_id == 1 && self.status.bigcommerce_id == 1
      status_id = self.status_id
    else
      status_id = Status.where('bigcommerce_id = ?', order.status_id).order('statuses.order').first.id
    end

    params = {'customer_id': order.customer_id, 'staff_id': customer.staff_id,\
      'status_id': status_id,\
      'total_inc_tax': order.total_inc_tax, 'qty': order.items_total, 'items_shipped': order.items_shipped,\
      'subtotal': order.subtotal_inc_tax.to_f/1.1 + order.discount_amount.to_f + order.coupon_discount.to_f,\
      'discount_rate': 0, 'discount_amount': order.discount_amount.to_f + order.coupon_discount.to_f,\
       'handling_cost': order.items_total.to_f * 1.82, 'shipping_cost': order.shipping_cost_ex_tax,\
       'wrapping_cost': order.wrapping_cost_ex_tax, 'wet': (order.subtotal_ex_tax.to_f - order.discount_amount.to_f - order.coupon_discount.to_f) * 0.29,\
       'gst': order.total_inc_tax.to_f / 11, 'staff_notes': remove_apostrophe(order.staff_notes),\
       'customer_notes': remove_apostrophe(order.customer_message), 'active': convert_bool(order.is_deleted),\
       'date_shipped': map_date(order.date_shipped), 'address': customer.address}
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

  # filter orders by multiple customer_staffs relationship order by customer staffs
  def self.customer_staffs_filter(staff_ids)
    return includes(:customer).where('customers.staff_id IN (?)', staff_ids).references(:customers) unless staff_ids.nil?
    all
  end

  # filter orders by customer_staff relationship
  def self.customer_staff_filter(staff_id)
    return includes(:customer).where('customers.staff_id = ?', staff_id).references(:customers) unless staff_id.nil?
    all
  end

  # filter orders by order_staff relationship
  def self.order_staff_filter(staff_id)
    return where('staff_id = ?', staff_id).references(:customers) unless staff_id.nil?
    all
  end

  def self.product_customer_filter(product_ids, customer_ids)
    return includes(:order_products).where('order_products.product_id IN (?)', product_ids).references(:order_products) if customer_ids.nil? || customer_ids.empty?
    includes(:order_products).where('order_products.product_id IN (?) OR orders.customer_id IN (?)', product_ids, customer_ids).references(:order_products)
  end

  # Returns orders whose date created is between the start date and end date
  # If you want today's orders
  # Then start date should be Today's date and end date should also be today -- Tomorrow's date --
  # Since date_created is stored as datetime in the database, these start and end dates are
  # converted into datetime values, with 00:00:00 as the time factor.
  def self.date_filter(start_date, end_date)
    if !start_date.nil? && !end_date.nil?
      if !start_date.to_s.empty? && !end_date.to_s.empty?
        start_time = Time.parse(start_date.to_s).at_beginning_of_day  # start from time 00:00:00
        end_time = Time.parse(end_date.to_s).at_end_of_day            # conclude at time 23:59:59

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

  # Problem status include Account Status
  def self.problem_status_filter
    joins(:status).where('statuses.send_reminder = 1 OR (orders.account_status != "Approved" AND statuses.valid_order = 1 AND statuses.in_transit = 0 AND statuses.delivered = 0)')
  end

  def self.courier_not_confirmed
    return joins(:courier_status).where('courier_statuses.confirmed': 0)
  end

  def self.statuses_filter(status_id)
    # return where(status_id: status_id, courier_status_id: 1) if (!status_id.nil?) && (status_id.include?8) && !(status_id.include?2)
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
    # DEPRECATED as the week start Sunday by default
    # Ref: https://www.w3resource.com/mysql/date-and-time-functions/mysql-week-function.php
    # includes(:customer).group(['customers.staff_id', 'WEEK(orders.date_created)'])

    # Start each week on Monday
    includes(:customer).group(['customers.staff_id', 'WEEK(orders.date_created, 1)'])
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

  def self.group_by_date_created_and_order_staff_id
    group(['staff_id', 'DATE(orders.date_created)'])
  end

  # Start the week on Monday
  def self.group_by_week_created_and_order_staff_id
    group(['staff_id', 'WEEK(orders.date_created, 1)'])
  end

  def self.group_by_month_created_and_order_staff_id
    group(['staff_id', 'MONTH(orders.date_created)', 'YEAR(orders.date_created)'])
  end

  def self.group_by_quarter_created_and_order_staff_id
    group(['staff_id', 'QUARTER(orders.date_created)', 'YEAR(orders.date_created)'])
  end

  def self.group_by_year_created_and_order_staff_id
    group(['staff_id', 'YEAR(orders.date_created)'])
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

  # return weekly sale figure by customer id
  def self.group_by_week_created_and_customer_id
    includes(:customer)
    .group(['customers.id', 'WEEK(orders.date_created, 1)', 'YEAR(orders.date_created)'])
    .references(:customers)
  end

  # return monthly sale figure by customer id
  def self.group_by_month_created_and_customer_id
    includes(:customer)
    .group(['customers.id', 'MONTH(orders.date_created)', 'YEAR(orders.date_created)'])
    .references(:customers)
  end

  # return quarterly sale figure by customer id
  def self.group_by_quarter_created_and_customer_id
    includes(:customer)
    .group(['customers.id', 'QUARTER(orders.date_created)', 'YEAR(orders.date_created)'])
    .references(:customers)
  end

  # return yearly sale figure by customer id
  def self.group_by_year_created_and_customer_id
    includes(:customer).group(['customers.id', 'YEAR(orders.date_created)']).references(:customers)
  end

  # return weekly sale figure by customer actual name
  def self.group_by_week_created_and_customer_actual_name
    includes(:customer)
    .group(['customers.actual_name', 'WEEK(orders.date_created, 1)', 'YEAR(orders.date_created)'])
    .references(:customers)
  end

  # return monthly sale figure by customer actual name
  def self.group_by_month_created_and_customer_actual_name
    includes(:customer)
    .group(['customers.actual_name', 'MONTH(orders.date_created)', 'YEAR(orders.date_created)'])
    .references(:customers)
  end

  # return quarterly sale figure by customer actual name
  def self.group_by_quarter_created_and_customer_actual_name
    includes(:customer)
    .group(['customers.actual_name', 'QUARTER(orders.date_created)', 'YEAR(orders.date_created)'])
    .references(:customers)
  end

  # return yearly sale figure by customer actual name
  def self.group_by_year_created_and_customer_actual_name
    includes(:customer).group(['customers.actual_name','YEAR(orders.date_created)']).references(:customers)
  end

  def self.group_by_cust_name_order_id
    includes(:customer)
    .group('customers.actual_name', 'orders.id')
  end

  # def self.group_by_orderid
  #   group('orders.id')
  # end

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

  # get quaterly sale figures of each staff and return them
  # def self.group_by_quarter_created_and_customer_id
  #   includes(:customer)
  #   .group(['customers.actual_name', 'QUARTER(orders.date_created)', 'YEAR(orders.date_created)'])
  #   .references(:customers)
  # end

  ########## SUMMATION FUNCTIONS ############

  def self.count_order_id_from_order_products
    includes(:order_products).count('order_products.order_id')
  end

  def self.count_orders
    count('orders.id')
  end

  # count products of each order by its product name without year
  # ie. Anarkia Tannat 2016 and Anarkia Tannat 2017 are of the same product
  def self.count_product_lines
    includes(:order_products => :product).count('products.name_no_vintage', :distinct => true)
  end

  # average product prices of each order
  def self.avg_luc
    includes(:order_products).average('order_products.price_luc')
  end

  def self.sum_total
    sum('orders.total_inc_tax')
  end

  # total number of bottles per order
  def self.sum_qty
    sum('orders.qty')
  end

  def self.avg_order_total
    average('orders.total_inc_tax')
  end

  def self.avg_order_qty
    average('orders.qty')
  end

  def self.sum_order_product_qty
    includes(:order_products).sum('order_products.qty')
  end

  def self.avg_bottle_price
  end


  ######### ORDER BY FUNCTIONS ############

  def self.order_by_id(direction)
    order('orders.date_created ' + direction)
  end

  def self.order_by_customer(direction = 'asc')
    includes(:customer).order('customers.actual_name ' + direction)
  end

  def self.order_by_staff(direction = 'asc')
    includes(:staff).order('staffs.nickname ' + direction)
  end

  def self.order_by_staff_customer(staff_direction = 'asc', customer_direction = 'asc')
    includes(:customer).order(
      'customers.staff_id ' + staff_direction + 
      ', customers.actual_name ' + customer_direction
    )
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
    includes(:xero_invoice).where('ROUND(orders.total_inc_tax, 2) <> Round(xero_invoices.total, 2)').references(:xero_invoice)
  end

  # return sample order and products
  def self.sample_orders
    where('orders.qty > 0 AND orders.total_inc_tax = 0')
  end

  # WHERE DO I USE THIS?
  def self.filter_by_product(product_ids)
    includes(:products).where('products.id IN (?)', [product_ids]).references(:products)
  end

  def order_sum
    order_total = 0.0
    self.order_products.each {|o| order_total += (o.qty * o.price_inc_tax)}
    return order_total
  end

  # sum ordered quantity
  # def self.sum_qty

  def display_ship_address
    self.ship_name.to_s + ' ' + self.street.to_s + ' ' + self.street_2.to_s + ' ' + self.city.to_s + ' ' + self.postcode.to_s + ' ' + self.country.to_s
  end

  private
  def order_shipped
    sql = "Update orders SET date_shipped = '#{Time.now.to_s(:db)}' WHERE id = #{self.id}"
    ActiveRecord::Base.connection.execute(sql)
  end

  def order_completed
    if self.total_inc_tax.zero? || (self.xero_invoice && self.xero_invoice.amount_due.zero?)
      sql = "Update orders SET status_id = 10 WHERE id = #{self.id}"
      ActiveRecord::Base.connection.execute(sql)
    end
  end

  def bigcommerce_status_update
    # Ignore lagacy datas
    return if self.id < 20000
    Bigcommerce::Order.update(self.source_id, status_id: self.status.bigcommerce_id)
  end

  def update_notes
    Bigcommerce::Order.update(self.source_id, staff_notes: self.staff_notes.to_s.gsub("''","'"), customer_message: self.customer_notes.to_s.gsub("''","'"))
  end

  def cancel_order
    self.order_products.map(&:delete_product)
  end

  def recovery_order
    self.order_products.map(&:recovery_product)
  end

  def record_history
    order_attributes =  "('#{self.id_was}', '#{self.customer_id_was}', '#{self.status_id_was}',\
    '#{self.courier_status_id_was}', '#{self.account_status_was}', \"#{self.street_was}\", \"#{self.city_was}\",\
    \"#{self.state_was}\", \"#{self.postcode_was}\", '#{self.country_was}', \"#{self.address_was}\",\
    '#{self.staff_id_was}', '#{self.total_inc_tax_was.to_f}', '#{self.qty_was.to_i}', '#{self.items_shipped_was.to_i}',\
    '#{self.subtotal_was.to_f}', '#{self.discount_rate_was.to_f}', '#{self.discount_amount_was.to_f}',\
    '#{self.handling_cost_was.to_f}', '#{self.shipping_cost_was.to_f}', '#{self.wrapping_cost_was.to_f}',\
    '#{self.wet_was.to_f}', '#{self.gst_was.to_f}',\
    '#{self.active_was.to_i}', '#{self.xero_invoice_id_was.to_s}', '#{self.xero_invoice_number_was.to_s}',\
    '#{self.source_was.to_s}', '#{self.source_id_was.to_s}', '#{self.date_created_was.to_s(:db)}',\
    '#{self.created_by_was.to_i}', '#{self.last_updated_by_was.to_i}', '#{Time.now.to_s(:db)}', '#{self.updated_at_was.to_s(:db)}')"
    sql = "INSERT INTO order_histories(order_id, customer_id, status_id, courier_status_id,\
    account_status, street, city, state, postcode, country, address, staff_id,\
    total_inc_tax, qty, items_shipped, subtotal, discount_rate, discount_amount,\
    handling_cost, shipping_cost, wrapping_cost, wet, gst,\
    active, xero_invoice_id, xero_invoice_number, source, source_id, date_created,\
    created_by, last_updated_by, created_at, updated_at) VALUES #{order_attributes}"

    ActiveRecord::Base.connection.execute(sql)
  end

  # # # # # # # # # #
  #  added by vchar #
  # # # # # # # # # #
  
  # Returns orders with valid status or marked as allocation (id = 1)
  # this method is used to fix a coincicent correctness which causes 
  # incorrect report of pending status page on the product summary page,
  # more specifically, products allocated to customers who have never
  # bought it before will not be shown in the report.
  def self.valid_and_allocated_orders
    includes(:status).where('statuses.valid_order = 1 OR status_id = 1').references(:statuses)
  end

  # this method is created in corresponding to the coincident correntness
  # issue as commented above the valid_and_allocated_orders method.
  # this method actually tries to sum all orders except allocated ones.
  def self.sum_order_product_qty_except_allocated
    includes(:order_products).sum('order_products.qty')
  end

end
