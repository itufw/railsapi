require 'application_helper.rb'
module SalesHelper
  include ApplicationHelper
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

  def total_cell_start_date(dates_map)
  	dates_map.values.flatten.first
  end

  def total_cell_end_date(dates_map)
  	dates_map.values.flatten.last
  end

  def sort_by_arrows(params, price_h, product_name_h, inventory_h, pending_stock_h,producu_qty_h)
    order_col = params["order_col"] || "order_by_id"
    direction = params["direction"] || "1"
    case order_col
    when "order_by_id"
      return ("1".eql? direction) ? price_h.sort_by {|key,value| key}.to_h : price_h.sort_by {|key,value| key}.reverse.to_h
    when "order_by_name"
      return sort_by_arrows_direction(product_name_h,direction)
    when "order_by_price"
      return sort_by_arrows_direction(price_h,direction)
    when "order_by_stock"
      stock = {}
      inventory_h.keys.each do |id|
        stock[id] = @inventory_h[id].to_i + @pending_stock_h[id].to_i
      end
      return sort_by_arrows_direction(stock,direction)
    when "order_by_total"
      total = {}
      price_h.keys.each do |id|
        total[id] = give_sum_date_h(id,producu_qty_h).values.sum
      end
      return sort_by_arrows_direction(total,direction)
    else
      return price_h
    end
  end

  def sort_by_arrows_direction(h,direction)
    return ("1".eql? direction) ? h.sort_by {|key,value| value}.to_h : h.sort_by {|key,value| value}.reverse.to_h
  end
end
