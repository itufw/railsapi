module SalesHelper
  
  # Takes input staff id and a Hash like {[staff_id, date] => sum}
  # Returns a Hash like {staff_id => sum}
  def sums_dates_h_for_staff(staff_id, sums_dates_staffs_h)
  	filter_by_staff = sums_dates_staffs_h.select {|key, sum| key[0] == staff_id}

  	sums_dates_h = Hash.new
  	filter_by_staff.each {|key, sum| sums_dates_h[key[1]] = sum}
  	return sums_dates_h
  end

end
