module DashboardMath
	# In a dashboard a period defines one column.
  	# Each column has a start date and an end date
  	# A user can choose these start and end dates to be divided into
  	# weekly segments, monthly or quarterly
  	# the number of columns can be minimum 3 and maximum 15.

	# returns a string that defines the current period type
	# depends on what the user selects. If the user selects nothing,
	# then the default is "monthly"
	# and a list of all the period types as strings - weekly, monthly, quarterly
	def current_period_type(params)
	    period_types = ["weekly", "monthly", "quarterly"]
	    if params[:period_type]
	      selected_period = params[:period_type]
	    else
	      selected_period = "monthly"
	    end
	    return selected_period, period_types
  	end

  	# returns an int that defines the current number of periods, default is 13
  	# and an array of ints - 3..15
  	def num_of_periods(params)
  		periods = (3..15).to_a
  		if params[:num_period]
  			return params[:num_period].to_i, periods
  		else
  			return 13, periods
  		end
  	end

  	# depending on the period type, returns the number of days that define that period
  	def num_days_for_periods(period_type)
  		days_period_h = { "weekly" => 7, "monthly" => 30, "quarterly" => 65 }
	    if days_period_h.has_key? period_type
	    	return days_period_h[period_type]
	    else
	    	return 1
	    end
  	end

  	# returns a sum function for Orders as a symbol
  	def sum_function_orders(selected, default)
	    sum_params_h = {"Order Totals" => :sum_total, "Bottles" => :sum_qty,\
	     "Number of Orders" => :count_orders, "Avg. Order Total" => :avg_order_total,\
	      "Avg. Bottles" => :avg_order_qty}

	    if selected.nil?
	      selected = default
	    end
	    return sum_params_h[selected], selected, sum_params_h.keys
  	end

end