# Time Periods are stored in Staff Time Period model.
# This module provides functions to display various stats depending on those time periods
# and also sort those stats by each time period

# Time periods are objects like "This Month", "Last Month", etc
# Time periods have a start and end date that changes dynamically in the database
# Visible Time periods are different for every user

module TimePeriodStats

	def overall_stats(where_query, sum_by, calendar_period_type, total_stock)
		time_periods = StaffTimePeriod.display
		
		result_h = {}
		time_periods.each do |t| 

			# where query will be something like Order.product_filter(29)
			# i.e. we wants orders for product_id 29
			# then we want to filter those orders depending on the dates of the timeperiods 
			# then we want to either display the total qty for those orders, or order totals -
			# hence the sum_by function.
			total_sum = (eval where_query).date_filter(t.start_date.to_s, t.end_date.to_s).send(sum_by)
			average = average(t, total_sum, calendar_period_type)
			supply = supply(total_stock, average)
			result_h[t.name] = [total_sum, average, supply]
		end
		return result_h
	end

	# average can be monthly average or weekly average or quarterly average
	# daily average is multiplied by the number of days in the period
	def average(time_period, sum, calendar_period_type)

		calendar_periods = { "weekly" => 7, "monthly" => 30, "quarterly" => 65 }

		num_days = (time_period.end_date.to_date - time_period.start_date.to_date).to_i
      	avg = (sum.to_f/num_days)*(calendar_periods[calendar_period_type] || 1)

	end

	# supply is total/average
	# this is also different for different time periods
	def supply(total_stock, average)
		unless total_stock.nil?
        	if average == 0
          		return 0.0
        	else
          		return (total_stock/average)
        	end
      	end
	end

	# returns top products for a customer
	# or 
	def top_objects(where_query, group_by, sum_by)
		time_periods = StaffTimePeriod.display

		result_h = {}
		time_periods.each do |t| 
			# result_h will be a hash like {"Last Month" => {29 => 1}}
			# 29 is product_id, 1 is the number of bottles sold in that time period

			# group_by decides if it is product_id or customer_id, etc
			# do we want to see number of bottles sold, or order totals is decided by sum_by
			unless group_by.empty?
				result_h[t.name] = (eval where_query).date_filter(t.start_date.to_s, t.end_date.to_s).\
				send(group_by).send(sum_by)
			end	
		end
		object_ids = result_h.values.reduce(&:merge).keys unless result_h.blank?
		return result_h, object_ids

	end

end