module SalesHelper
  
  # Takes input staff id and a Hash like {[staff_id, date] => sum}
  # Returns a Hash like {date => sum}
  def sums_dates_h_for_staff(staff_id, sums_dates_staffs_h)
  	filter_by_staff = sums_dates_staffs_h.select {|key, sum| key[0] == staff_id}

  	sums_dates_h = Hash.new
    #sums_dates_h[staff_id] = filter_by_staff.values.sum
  	filter_by_staff.each {|key, sum| sums_dates_h[new_key(key)] = sum}
  	return sums_dates_h
  end

  def new_key(key)
    if key[1..-1].count == 1
      new_key = key[1]
    else
      new_key = key[1..-1]
    end
    return new_key
  end

  def total_cell_start_date(dates_map)
  	dates_map.values.flatten.first
  end

  def total_cell_end_date(dates_map)
  	dates_map.values.flatten.last
  end

end
