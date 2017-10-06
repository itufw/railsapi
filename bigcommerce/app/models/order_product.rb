require 'bigcommerce_connection.rb'

class OrderProduct < ActiveRecord::Base
	belongs_to :order
	belongs_to :product, class_name: Product

	belongs_to :order_shipping

	after_validation :record_history, on: [:update, :delete]
	after_validation :stock_change, on: [:create, :update], if: ->(obj){ obj.stock_incremental.present? and obj.stock_incremental_changed? and obj.stock_incremental!=0 }
	after_validation :product_display_check, on:[:update], if: ->(obj){ obj.stock_current_changed?}

	def import_from_bigcommerce(order, op)
		attributes = {'order_id': order.id, 'product_id': op.product_id, 'price_luc': op.base_price.to_f * 1.29,\
			'base_price': op.base_price, 'qty': op.quantity, 'discount': 0, 'price_discounted': op.base_price.to_f * 1.29,\
			'order_discount': order.discount_rate, 'price_handling': 1.82, 'price_inc_tax': op.price_inc_tax,\
		  'price_wet': op.base_price.to_f * 0.29, 'price_gst': op.price_inc_tax.to_f / 11, 'stock_previous': self.stock_current,\
		  'stock_current': op.quantity, 'stock_incremental': op.quantity - self.stock_current.to_i,\
		  'display':(op.quantity == 0) ? 0 : 1, 'damaged': 0, 'created_by': 34, 'updated_by': 34}
		self.update_attributes(attributes)
		self
	end

	def delete_product
		attributes = {'qty': 0, 'stock_previous': self.stock_current, 'stock_current': 0, 'stock_incremental': 0 - self.stock_current,\
			'display': 0, 'updated_by': 34}
		self.update_attributes(attributes)
		self
	end

	def recovery_product
		attribuets = {'stock_previous': self.stock_current, 'stock_current': 0 - self.stock_incremental,\
			 'stock_incremental': 0 - self.stock_incremental, 'display': 1, 'updated_by': 34}
		self.update_attributes(attributes)
		self
	end

	# find the products in allocation status
	def self.allocation_products(product_ids)
		joins(:order).where('orders.status_id': 1, product_id: product_ids)
	end

	def self.on_order(product_ids)
		joins(:order).where('orders.status_id': [9, 11, 20, 24, 26, 27], product_id: product_ids)
	end

	def self.ready(product_ids)
		joins(:order).where('orders.status_id': 25, product_id: product_ids)
	end

	# Inc Tax
	def self.order_sum(order_products)
		order_total = 0.0
		order_products.each {|o| order_total += (o.qty * o.price_inc_tax)}
		return order_total
	end

	def self.total_qty(order_product_id)
		return find(order_product_id).qty
	end

	def self.order_customer_filter(customer_ids)
		return includes(:order).where('orders.customer_id IN (?)', customer_ids).references(:orders) unless (customer_ids.nil? or  customer_ids.empty?)
		return all
	end

	def self.valid_orders
		includes([{:order => :status}]).where('statuses.valid_order = 1').references(:statuses)
	end

	def self.valid_products
		where(display: 1)
	end

	def self.staff_filter(staff_id)
		return all if staff_id.nil?
		return includes([{:order => :staff}]).where('staffs.id = ?', staff_id).references(:staffs)
	end

	def self.product_filter(product_ids)
		return all if product_ids.empty?
		return where('product_id IN (?)', product_ids)
	end

	def self.order_filter(order_ids)
		return where('order_id IN (?)', order_ids) unless ((order_ids.nil?) || (order_ids.empty?))
	end

	def self.cust_style_filter(cust_style_id)
		return all if cust_style_id.nil?
		return includes([{:order => :customer}]).where('customers.cust_style_id = ?', cust_style_id).references(:customers)
	end

	def self.date_filter(start_date, end_date)
		if (!start_date.nil? && !end_date.nil?)
			if !start_date.to_s.empty? && !end_date.to_s.empty?
			  start_time = Time.parse(start_date.to_s)
	          end_time = Time.parse(end_date.to_s)

			  return includes(:order).where('orders.date_created >= ? and orders.date_created <= ?', start_time.strftime("%Y-%m-%d %H:%M:%S"), end_time.strftime("%Y-%m-%d %H:%M:%S")).references(:orders)
			end
		end
		return all
	end

	def self.date_filter_end_date(end_date)
		if (!end_date.nil?)
			if !end_date.to_s.empty?
				end_time = Time.parse(end_date.to_s)
				return includes(:order).where('orders.date_created <= ?', end_time.strftime("%Y-%m-%d %H:%M:%S")).references(:orders)
			end
		end
		return all
		end

	def self.product_pending_stock(group_by)
		includes([{:order => :status}]).where('orders.status_id = 1').references(:orders).send(group_by).sum_qty
	end


	def self.group_by_product_id
		includes(:product).group('products.id').references(:products)
	end

	def self.group_by_product_no_vintage_id
		includes(:product).group('products.product_no_vintage_id').references(:products)
	end

	def self.group_by_product_no_ws_id
		includes(:product).group('products.product_no_ws_id').references(:products)
	end

	# GROUP BY DATE AND PRODUCT
	def self.group_by_week_created_and_product_id(product_transform_column)
        includes(:order, :product).group([get_product_id(product_transform_column),\
                                         'WEEK(orders.date_created)']).references(:orders, :products)
    end

    def self.group_by_month_created_and_product_id(product_transform_column)
        includes(:order, :product).group([get_product_id(product_transform_column),\
                                         'MONTH(orders.date_created)', 'YEAR(orders.date_created)']).\
        								  references(:orders, :products)
    end

    def self.group_by_quarter_created_and_product_id(product_transform_column)
        includes(:order, :product).group([get_product_id(product_transform_column),\
                                         'QUARTER(orders.date_created)', 'YEAR(orders.date_created)']).\
        								  references(:orders, :products)
    end

		def self.group_by_year_created_and_product_id(product_transform_column)
        includes(:order, :product).group([get_product_id(product_transform_column),\
                                        'YEAR(orders.date_created)']).references(:orders, :products)
    end


    def self.get_product_id(product_transform_column)
    	group_by_product_s = product_transform_column == 'product_id' ? 'products.id' : 'products.' + product_transform_column
    	return group_by_product_s
    end

	def self.sum_qty
		sum('order_products.qty')
	end

	# CHANGE THIS?
	def self.avg_order_qty
		average('order_products.qty')
	end

	def self.count_orders
        includes(:order).count('orders.id')
    end

    def self.sum_total
        includes(:order).sum('orders.total_inc_tax')
    end

    def self.avg_order_total
        includes(:order).average('orders.total_inc_tax')
    end

	# Price Range
	def self.max_price_inc_tax(max_price)
		where("price_inc_tax < #{max_price}")
	end

	def self.min_price_inc_tax(min_price)
		where("price_inc_tax > #{min_price}")
	end

	private
	# inventory trigger
	def stock_change
		# Do Not Change the Stock Level for bigcommerce Orders
		return if self.order.source == 'bigcommerce'
		# return if it was WINE CLUB (product) -> not real products
		return if [2427, 2582, 2341, 2579].include?self.product_id

		Bigcommerce::Product.update(self.product_id, inventory_level: Bigcommerce::Product.find(self.product_id).inventory_level - self.stock_incremental)
		sql = "UPDATE products SET inventory = inventory - '#{self.stock_incremental}' WHERE id = '#{self.product_id}'"
		ActiveRecord::Base.connection.execute(sql)
	end

	def product_display_check
		if self.qty > 0 && self.display == 0
			sql = "Update order_products SET display = 1 WHERE id = #{self.id}"
			ActiveRecord::Base.connection.execute(sql)
		elsif self.qty <= 0 && self.display == 1
			sql = "Update order_products SET display = 0 WHERE id = #{self.id}"
			ActiveRecord::Base.connection.execute(sql)
		end
	end

	def record_history
		order_history = OrderHistory.where(order_id: self.order_id).order('id DESC').first
		return if order_history.nil?
		order_history_id = order_history.id

		product_attributes =  "('#{self.order_id_was.to_i}', '#{order_history.id}', '#{self.product_id_was.to_i}',\
		'#{self.order_shipping_id_was.to_i}', '#{self.qty_was.to_i}', '#{self.qty_shipped_was.to_i}', '#{self.price_luc_was.to_f}',\
		'#{self.base_price_was.to_f}', '#{self.discount_was.to_f}', '#{self.order_discount_was.to_f}', '#{self.price_handling_was.to_f}',\
		'#{self.price_inc_tax_was.to_f}', '#{self.price_wet_was.to_f}', '#{self.price_gst_was.to_f}', '#{self.price_discounted_was.to_f}',\
		'#{self.stock_previous_was.to_i}', '#{self.stock_current_was.to_i}', '#{self.stock_incremental_was.to_i}',\
		'#{self.display_was.to_i}', '#{self.damaged_was.to_i}', '#{self.note_was.to_s}', '#{self.created_by_was.to_s}',\
		'#{self.updated_by_was.to_s}', '#{self.created_at_was.to_s(:db)}', '#{self.updated_at_was.to_s(:db)}')"

		sql = "INSERT INTO order_product_histories(order_id, order_history_id, product_id,\
		order_shipping_id, qty, qty_shipped, price_luc, base_price, discount, order_discount,\
		price_handling, price_inc_tax, price_wet, price_gst, price_discounted, stock_previous,\
		stock_current, stock_incremental, display, damaged, note, created_by, updated_by,\
		created_at, updated_at) VALUES #{product_attributes}"
		ActiveRecord::Base.connection.execute(sql)
	end
end
