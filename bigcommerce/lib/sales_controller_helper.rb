module SalesControllerHelper

  # returns a hash where dates (and sometime staff id) are keys and values are positive, 
  # non-zero orders totals 
  def sum_orders(start_date, end_date, group_by_date_function, sum_function, staff_id)
      return Order.date_filter(start_date, end_date.next_day).valid_order.staff_filter(staff_id).send(group_by_date_function).send(sum_function)
  end

  def staff_dropdown
  	return Staff.active_sales_staff
  end

  def order_sum_param(radio_button_value)
    if radio_button_value == "Bottles"
      return :sum_qty, true, false, "Bottles"
    else
      return :sum_total, false, true, "Order Totals"
    end
  end

  def stats_for_timeperiods(where_query, group_by, sum_by, total_stock, period_type)
    time_periods = StaffTimePeriod.display

    # this is the stat per row and column, for eg. This is qty sold for each customer per time period
    overall_h = Hash.new
    # this is the stat per column, for eg. this is the total qty sold in one time period
    overall_sum = []
    overall_avg = []
    monthly_supply = []

    time_periods.each do |t| 

      overall_h[t.name] = (eval where_query).date_filter(t.start_date.to_s, t.end_date.to_s).send(group_by).send(sum_by) unless group_by.empty?
        
      sum = (eval where_query).date_filter(t.start_date.to_s, t.end_date.to_s).send(sum_by)
      num_days = (t.end_date.to_date - t.start_date.to_date).to_i

      avg = (sum.to_f/num_days)*(num_days_for_periods(period_type))
        
      overall_sum.push(sum)
      overall_avg.push(avg)
      unless total_stock.nil?
        if avg == 0
          monthly_supply.push(0.0)
        else
          monthly_supply.push(total_stock/avg)
        end
      end

    end

    ids = overall_h.values.reduce(&:merge).keys unless overall_h.blank?
    [time_periods.pluck("name"), overall_h, overall_sum, overall_avg, ids, monthly_supply]
  end

  def return_nil_string(val)
    if val.nil?
      return "nil"
    else
      return val
    end
  end

  # Returns a array like
  # [[product_id, [number_of_orders, status_qty, orders_dollar_sum, product_name, product_stock]]
  def products_for_status(status_id, staff_id, product_ids)
    # Now I need to make a hash like from orders
    #{product_id => [number_of_orders, status_qty, orders_dollar_sum, product_name, product_stock]}

    filter_string = "Order.status_filter(%s).staff_filter(%s).product_filter(%s)" % [status_id, return_nil_string(staff_id), product_ids]

    # This returns a hash like {product_id => number_orders}
    num_orders = (eval filter_string).group_by_product_id.count_order_id_from_order_products

    # This returns a hash like {product_id => product_qty sum over all the valid orders}
    product_qty = (eval filter_string).group_by_product_id.sum_order_product_qty

    # This returns a hash like {product_id => money sum of all the orders that has this product}
    # Note its the sum of the total_inc_tax of the order, not the sum of that individual product's money
    order_totals = (eval filter_string).group_by_product_id.sum_total

    # Now we need to merge them
    merge_1 = num_orders.merge(product_qty) { |k, o, n| [o, n] }
    merge_2 = merge_1.merge(order_totals) { |k, o, n| o.push(n)}

    # Now we have a hash called merge_2 like {product_id => [num_orders, product_qty, order_total]}
    valid_products_a = Product.filter_by_ids(merge_2.keys).pluck("id,name,inventory")

    # Create a hash {product_id => product_name, product_stock }
    valid_products_h = Hash[valid_products_a.map{|id,name,inventory| [id,[name,inventory]] if !id.nil?}]

    merge_2.select! {|k| valid_products_h.keys.include? k}

    # Merge into one final thing
    product_h = merge_2.merge(valid_products_h) { |k, o, n| o.concat(n) if valid_products_h.has_key?(k)}

    products = Hash[product_h.sort_by { |k,v| v[3] }]

    return products.to_a
  end

  def define_period_types(params)
    period_types = ["weekly", "monthly"]
    if params[:period_type]
      selected_period = params[:period_type]
    else
      selected_period = "monthly"
    end
    return selected_period, period_types
  end

  def num_days_for_periods(period_type)
    if period_type == "weekly"
      return 7
    elsif period_type == "monthly"
      return 30
    else
      return 1
    end
  end
      
end