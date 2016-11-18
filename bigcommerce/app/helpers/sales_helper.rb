module SalesHelper
  
  # Takes input staff id and a Hash like {[staff_id, date] => sum}
  # Returns a Hash like {date => sum} for that particular staff_id
  # Here sum is the sum of order_totals for that particular staff on that date
  def sums_dates_h_for_staff(staff_id, sums_dates_staffs_h)
  	filter_by_staff = sums_dates_staffs_h.select {|key, sum| key[0] == staff_id}

  	sums_dates_h = Hash.new
    #sums_dates_h[staff_id] = filter_by_staff.values.sum
  	filter_by_staff.each {|key, sum| sums_dates_h[new_key(key)] = sum}
  	return sums_dates_h
  end

  # Takes input a date, a Hash like {[staff_id, date] => sum} and a hash of staffs like {staff_id => nickname}
  # Returns a Hash like {date => sum} where sum is the sum of order_totals/bottles 
  # for all the active staffs for that date
  def staff_sums_total(dates, sums_dates_staffs_h, staffs)
    dates_total_h = Hash.new
    dates.each do |d|
      filter_by_date = sums_dates_staffs_h.select {|key, sum| new_key(key) == d && staff_is_active(key[0], staffs) == 1}
      dates_total_h[d] = filter_by_date.values.sum
    end
    return dates_total_h
  end

  def staff_is_active(staff_id, staffs)
    if staffs.keys.include? staff_id
      return 1
    else
      return 0
    end
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
