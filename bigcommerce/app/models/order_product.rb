class OrderProduct < ActiveRecord::Base
	belongs_to :order
	belongs_to :product, class_name: Product

	belongs_to :order_shipping

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
end
