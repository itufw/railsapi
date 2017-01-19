class OrderProduct < ActiveRecord::Base
	belongs_to :order
	belongs_to :product, class_name: Product

	belongs_to :order_shipping

	def insert(order_id)

		order_product_api = Bigcommerce::OrderProduct
		order_products = order_product_api.all(order_id)

		if order_products.blank?
			return
		end

		order_products.each do |op|
			time = Time.now.to_s(:db)
		  	inserts_products = "('#{op.order_id}', '#{op.product_id}', '#{op.order_address_id}',\
		  	'#{op.quantity}', '#{op.quantity_shipped}', '#{op.base_price}', '#{op.price_ex_tax}',\
		  	'#{op.price_inc_tax}', '#{op.price_tax}', '#{time}', '#{time}')"

		  	sql_products = "INSERT INTO order_products (order_id, product_id, order_shipping_id, qty,\
		  	qty_shipped, base_price, price_ex_tax, price_inc_tax, price_tax,\
			created_at, updated_at) VALUES #{inserts_products}"

			ActiveRecord::Base.connection.execute(sql_products)

		end
	end

	def delete(order_id)
		delete_order_product = "DELETE FROM order_products WHERE order_id = '#{order_id}'"
	    ActiveRecord::Base.connection.execute(delete_order_product)
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

	def self.staff_filter(staff_id)
		return all if staff_id.nil?
		return includes([{:order => :staff}]).where('staffs.id = ?', staff_id).references(:staffs)
	end

	def self.product_filter(product_ids)
		return all if product_ids.empty?
		return where('product_id IN (?)', product_ids)
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

end
