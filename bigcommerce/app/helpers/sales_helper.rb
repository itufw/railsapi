module SalesHelper
  
  # def display_staff_totals(active_sales_id, dates_a, sales_totals_h)

  # 	dates_a.each do |d|
  # 	  staff_key = [active_sales_id, d]
  #     if sales_totals_h.has_key?(staff_key)

  # 	end

  # end

  def sums_dates_h_for_staff(staff_id, sums_dates_staffs_h)
  	filter_by_staff = sums_dates_staffs_h.select {|key, sum| key[0] == staff_id}

  	sums_dates_h = Hash.new
  	filter_by_staff.each {|key, sum| sums_dates_h[key[1]] = sum}
  	return sums_dates_h
  end

end
