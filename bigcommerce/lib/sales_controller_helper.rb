module SalesControllerHelper

  # If a set date isnt given then start of the week is current week's start
  # if date is given, then start of the week is given date

  # End date in any case is 7 days after the start date

  # Returns an array containing week's date
  def this_week(date_given)

  	if date_given.blank?
  	  start_date = (Date.today).at_beginning_of_week
  	else
  	  start_date = date_given
  	end

  	end_date = 6.days.since(start_date)

  	return (start_date..end_date).to_a
  end

  def last_week(start_date)

  	last_week_start_date = start_date - 7.days
  	last_week_end_date = 6.days.since(last_week_start_date)

  	return (last_week_start_date..last_week_end_date).to_a
  end

  def make_daily_dates_map(dates_a)
    dates_map = {}
    dates_a.each {|d| dates_map[d] = [d, d.next_day]}
    return dates_map
  end

  # def weekly_periods_next(periods, start_date)
  #   week_start_dates_a = []
  #   next_date = start_date

  #   periods.times do 
  #     week_start_dates_a.push(next_date)
  #     next_date = next_date.next_week
  #   end
  #   end_date = next_date.end_of_week
  #   return start_date, week_start_dates_a.sort, end_date
  # end

  # def weekly_periods_last(periods, end_date)
  #   week_start_dates_a = []
  #   last_date = end_date.beginning_of_week

  #   periods.times do 
  #     week_start_dates_a.push(last_date)
  #     last_date = last_date.last_week
  #   end
  #   week_start_dates_a = week_start_dates_a.sort
  #   return week_start_dates_a[0], week_start_dates_a, end_date
  # end

  def get_last_weeks_date(num_times, end_date)
    last_weeks_dates = []
    current_date = end_date
    num_times.times do
      last_weeks_dates.push(current_date.last_week)
      current_date = current_date.last_week
    end
    return last_weeks_dates
  end

  # Gives a sorted array of dates
  # where first element is the date, number of periods before the end_date
  # a period can be defined by a function
  def periods_from_end_date(num_periods, end_date)
    all_dates = []
    all_dates.push(end_date.next_day)
    if end_date.beginning_of_week == end_date
      # It is a Monday
      return (all_dates + get_last_weeks_date(num_periods, end_date)).sort
    else
      # Not a Monday
      # That week's monday - given end date will be one period
      # num_periods - 1 will be normal Weekly periods
      all_dates.push(end_date.beginning_of_week)
      return (all_dates + get_last_weeks_date(num_periods - 1, end_date.beginning_of_week)).sort      
    end
  end

  # Returns a hash where key is the week number and value is an array of start date and end date
  def pair_dates(dates_a)
    paired_dates_a = {}
    dates_a.each_cons(2) {|date, next_date| paired_dates_a[convert_to_week_num(date)] = [date, next_date] unless date.equal? dates_a.last}
    return paired_dates_a
  end

  def convert_to_week_num(date)
    return date.strftime('%U').to_i
  end

  # returns a hash where dates are keys and values are positive, non-zero orders totals 
  def sum_orders(start_date, end_date, group_by_function)
      return Order.date_filter(start_date, end_date).valid_order.send(group_by_function).sum_total
  end

  def staff_sum_orders(start_date, end_date, group_by_function)
  	return Order.date_filter(start_date, end_date).valid_order.send(group_by_function).sum_total
  end

  def staff_dropdown
  	return Staff.active_sales_staff
  end

  def stats_for_timeperiods(where_query, group_by, sum_by)
    time_periods = StaffTimePeriod.display

    # this is the stat per row and column, for eg. This is qty sold for each customer per time period
    overall_h = Hash.new
    # this is the stat per column, for eg. this is the total qty sold in one time period
    overall_sum = []
    overall_avg = []

    time_periods.each do |t| 

      overall_h[t.name] = (eval where_query).date_filter(t.start_date.to_s, t.end_date.to_s).send(group_by).send(sum_by) unless group_by.empty?
        
      sum = (eval where_query).date_filter(t.start_date.to_s, t.end_date.to_s).send(sum_by)
      num_days = (t.end_date.to_date - t.start_date.to_date).to_i
      avg = (sum.to_f/num_days)*(7)
        
      overall_sum.push(sum)
      overall_avg.push(avg)
    end

    ids = overall_h.values.reduce(&:merge).keys unless overall_h.blank?
    [time_periods.pluck("name"), overall_h, overall_sum, overall_avg, ids]
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

    filter_string = "Order.status_filter(%s).staff_filter(nil).product_filter(%s)" % [status_id, return_nil_string(staff_id), product_ids]

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


end