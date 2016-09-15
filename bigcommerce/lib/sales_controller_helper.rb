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

  # returns a hash where dates are keys and values are positive, non-zero orders totals 
  def sum_orders(start_date, end_date)
      return Order.date_filter(start_date, end_date).valid_order.group_by_date_created.sum_total
  end

  def staff_sum_orders(start_date, end_date)
  	return Order.date_filter(start_date, end_date).valid_order.group_by_date_created_and_staff_id.sum_total
  end

  def staff_dropdown
  	return Staff.active_sales_staff
  end

  # Filters orders by search text, status id, product id, order id and staff id
  def orders_param_filter(params, status_id, product_id, order_id)

    staff_param_filter_result = staffs_param_filter(params)
  	if check_param_commit(params) && staff_param_filter_result

  	  staff_id = staff_param_filter_result[0]
      staff = staff_param_filter_result[1]

      orders_a = Order.status_filter(status_id).filter_order_products(product_id, order_id).staff_filter(staff_id)
    else
      orders_a = Order.status_filter(status_id).filter_order_products(product_id, order_id)
      staff = nil
    end
    return staff, orders_a
  end

  def products_param_filter(params, search_text, country_id, sub_type_id, product_ids)

  	product_h = Product.get_products(product_ids).pluck("id,name").to_h
    product_h_sorted = Hash[product_id_name_map.sort_by { |k,v| v }]

    return product_h_sorted

  end

  # Filters customers by search text, staff id and customer ids
  def customers_param_filter(params, search_text, customer_ids)

  	pluck_string = "customers.id, customers.actual_name, customers.firstname, customers.lastname, staffs.nickname"

  	staff_param_filter_result = staffs_param_filter(params)
  	if check_param_commit(params) && staff_param_filter_result

  	  staff_id = staff_param_filter_result[0]
      staff = staff_param_filter_result[1]

      customer_a = Customer.staff_search_filter(search_text, staff_id).get_customers(customer_ids).pluck(pluck_string)
    else
      customer_a = Customer.includes(:staff).get_customers(customer_ids).pluck(pluck_string)
      staff = nil    
    end

    customer_h = Hash[customer_a.map {|id, actual_name, firstname, lastname, staff| [id, [customer_name(firstname, lastname, actual_name), staff]]}]

    # Hash[customer_hash.sort_by { |k,v| v[0] }]
    return staff, customer_h
  end

  # Checks if somebody wants to filter by staff
  # If yes, then return staff id and staff row
  def staffs_param_filter(params)
  	if !params[:staff][:id].blank?
      staff_id = params[:staff][:id]
      staff = Staff.filter_by_id(staff_id)
      return staff_id, staff
    else
      return false
    end
  end

  # Checks if somebody clicked on a commit button
  def check_param_commit(params)
  	if params.has_key?(:commit)
  	  return 1
  	else
      return 0
    end
  end

  # Takes hash as its input, returns an array of keys and 0's 
  # CHANGE THIS
  def check_id_in_map(stats_array, id)
	values_for_one_time_periods = []

    stats_array.each do |s|
      if s.has_key? id
        values_for_one_time_periods.push(s[id])
      else
        values_for_one_time_periods.push(0)
      end
    end

    return values_for_one_time_periods
  end

  def stats_for_timeperiods(where_query, group_by, sum_by)
    time_periods = StaffTimePeriod.display

    # this is the stat per row and column, for eg. This is qty sold for each customer per time period
    stats_per_cell = []
    # this is the stat per column, for eg. this is the total qty sold in one time period
    stats_sum_per_t = []
    stats_avg_per_t = []

    time_periods.each do |t| 

      stats_per_cell.push((eval where_query).date_filter(t.start_date.to_s, t.end_date.to_s).send(group_by).send(sum_by)) if respond_to?(group_by)
        
      sum = (eval where_query).date_filter(t.start_date.to_s, t.end_date.to_s).send(sum_by)
      num_days = (t.end_date.to_date - t.start_date.to_date).to_i
      avg = (sum.to_f/num_days)*(7)
        
      stats_sum_per_t.push(sum)
      stats_avg_per_t.push(avg)
    end

    ids = stats_per_cell.reduce(&:merge).keys unless stats_per_cell.blank?
    [time_periods, stats_per_cell, stats_sum_per_t, stats_avg_per_t, ids]
  end

end