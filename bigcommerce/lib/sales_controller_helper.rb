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

end