require 'application_helper.rb'
require 'product_variations.rb'
require 'time_period_stats.rb'
module SalesHelper
  include ApplicationHelper
  include ProductVariations
  include TimePeriodStats

  def cust_group_sales(cust_group_id, start_date, end_date, cust_group_name, sum_function, dates_paired=nil)
      case sum_function
      when :sum_qty
        function = "sum(orders.qty)"
      when :count_orders
        function = "count(orders.id)"
      when :avg_order_total
        function = "avg(orders.total_inc_tax)"
      when :avg_order_qty
        function = "avg(orders.qty)"
      when :avg_bottle_price
        function = "sum(orders.qty) as qty, sum(orders.total_inc_tax)"
        gst = 1 + TaxPercentage.gst_percentage * 0.01
      else
        function = "sum(orders.total_inc_tax)"
      end

     sales = Customer.joins(:orders).select(" #{function} as sum, CAST(orders.date_created AS DATE) as date").\
                where("customers.cust_group_id = #{cust_group_id}").where("orders.date_created < '#{end_date}' AND orders.date_created > '#{start_date}'").\
                group("CAST(orders.date_created AS DATE)")
      cust_group_sums = {}
      sales.each do |daily_sale|
        cust_group_sums[daily_sale.date] = ((:avg_bottle_price).eql? sum_function) ? daily_sale.sum/(daily_sale.qty * gst) : daily_sale.sum
      end

      unless dates_paired.nil?
        cust_group_sums_h = {}
        dates_paired.keys().each do |date|
          begin_at = dates_paired[date].first
          end_at = dates_paired[date].last
          cust_group_sums_h[date] = cust_group_sums.select{|key, value| begin_at<=key && end_at>key}.values().sum
        end
        cust_group_sums = cust_group_sums_h
      end

      # cust_group_name = CustGroup.find(cust_group_id).name
    [cust_group_sums,cust_group_name]
  end

  # Takes input a date, a Hash like {[staff_id, date] => sum} and a hash of staffs like {staff_id => nickname}
  # Returns a Hash like {date => sum} where sum is the sum of order_totals/bottles
  # for all the active staffs for that date
  def staff_sums_total(dates, sums_dates_staffs_h, staffs)
    dates_total_h = Hash.new
    dates.each do |d|
      filter_by_date = sums_dates_staffs_h.select {|key, sum| new_key(key) == d && staff_is_active(key[0], staffs) == 1}
      dates_total_h[d] = @avg_sum ? filter_by_date.values.sum/filter_by_date.values.size.to_f : filter_by_date.values.sum if filter_by_date.values.size>0
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

  def sort_by_arrows(params, price_h, product_name_h, inventory_h, pending_stock_h,product_qty_h, product_ids)
    order_col = params["order_col"] || "return"
    direction = params["direction"] || "1"

    case order_col
    when "return"
      return product_ids
    when "order_by_id"
      return ("1".eql? direction) ? price_h.sort_by {|key,value| key}.to_h.keys : price_h.sort_by {|key,value| key}.reverse.to_h.keys
    when "order_by_name"
      return sort_by_arrows_direction(product_name_h,direction,price_h)
    when "order_by_price"
      return sort_by_arrows_direction(price_h,direction,price_h)
    when "order_by_pending"
      return sort_by_arrows_direction(pending_stock_h,direction,price_h)
    when "order_by_stock"
      stock = {}
      inventory_h.keys.each do |id|
        stock[id] = inventory_h[id].to_i + pending_stock_h[id].to_i
      end
      return sort_by_arrows_direction(stock,direction,price_h)
    when "order_by_total"
      total = {}
      price_h.keys.each do |id|
        total[id] = give_sum_date_h(id,product_qty_h).values.sum
      end
      return sort_by_arrows_direction(total,direction,price_h)
    end

    if order_col.include? "order_by_date"
      date_keys = order_col.split("_")
      date_key_array = date_keys.last.split(",")
      date_key = [date_keys.last.scan(/\d+/).first.to_i,date_keys.last.scan(/\d+/).last.to_i]

      total = {}
      price_h.keys.each do |id|
        total[id] = exists_in_h(give_sum_date_h(id, product_qty_h), date_key) unless " ".eql? exists_in_h(give_sum_date_h(id, product_qty_h), date_key)
      end
      return sort_by_arrows_direction(total,direction,price_h)

    end
  end

  def sort_by_arrows_direction(h,direction,price_h)
    h =  ("1".eql? direction) ? h.sort_by {|key,value| value}.to_h : h.sort_by {|key,value| value}.reverse.to_h
    product_id_filter = []
    h.keys.each do |id|
      product_id_filter.push(id)
    end
    price_h.keys.each do |id|
      (("-1".eql? direction) ? product_id_filter.push(id) : product_id_filter.unshift(id) ) unless product_id_filter.include? id
    end
    return product_id_filter
  end


  def filter_by_range(transform_column, product_ids, price_range,stock_range,sales_range, product_qty_h)
    price_h, product_name_h, inventory_h, pending_stock_h = get_data_after_transformation(transform_column, product_ids)

    # validation check
    price_range = range_validation(price_range)
    stock_range = range_validation(stock_range)
    sales_range = range_validation(sales_range)

    # price filter
    price_h.delete_if { |key, value| ((value < price_range[0].to_f)||(value > price_range[1].to_f)) }

    product_ids = price_h.keys

    # stock filter
    stock_h = {}
    product_ids.each do |id|
      stock_h[id] = inventory_h[id].to_i + pending_stock_h[id].to_i
    end
    stock_h.delete_if { |key, value| ((value < stock_range[0].to_f)||(value > stock_range[1].to_f))}

    product_ids = product_ids & stock_h.keys

    # sales filter
    sales_h = {}
    product_ids.each do |id|
      sales_h[id] = give_sum_date_h(id,product_qty_h).values.sum if (give_sum_date_h(id,product_qty_h).values.sum > sales_range[0] && give_sum_date_h(id,product_qty_h).values.sum < sales_range[1])
    end

    product_ids = product_ids & sales_h.keys

    # simplifer the world assignments
    price_h.delete_if { |key, value| !(product_ids.include?key)}
    product_name_h.delete_if { |key, value| !(product_ids.include?key)}
    inventory_h.delete_if { |key, value| !(product_ids.include?key)}
    pending_stock_h.delete_if { |key, value| !(product_ids.include?key)}
    product_qty_h.delete_if {|key, value| !(product_ids.include?key[0])}

    return product_ids, price_h, product_name_h, inventory_h, pending_stock_h, product_qty_h
  end

  def range_validation(range)
    range[0] = ((range[0].to_f.to_s == range[0].to_s)||((range[0].to_i.to_s == range[0].to_s))) ? range[0].to_f : 0
    range[1] = ((range[1].to_f.to_s == range[1].to_s)||((range[1].to_i.to_s == range[1].to_s))) ? range[1].to_f : 100000
    return range
  end


  # stats VIEW:
  def stats_info(product_ids, product_name_h, transform_column, inventory_h, pending_stock_h)
    stats_info = {}
    stats_sum = Array.new(StaffTimePeriod.display.count, 0)
    product_ids.each do |product_id|
      product_transform_ids = get_products_after_transformation(transform_column, product_id).pluck("id") || product_id
      # overall_stats has structure {time_period_name => [sum, average, supply]}
      overall_stats = overall_stats("Order.order_product_filter(%s).valid_order" % \
        [product_transform_ids], :sum_order_product_qty, "monthly", inventory_h[product_id].to_i+pending_stock_h[product_id].to_i)

      stats_info[product_id] = {"product_name" => product_name_h[product_id], "time_period" => overall_stats }
      stats_sum = [stats_sum, overall_stats.map{|x| x.last[0]}].transpose.map {|x| x.reduce(:+)}
    end
    # stats_info has structure {"product_name" => "name", "time_period" => {time_period_name => [sum, average, supply]}}
    return stats_info, stats_sum
  end

  def update_lables(product_ids, lable)
    relations = ProductLableRelation.lable_filter(lable)
    product_ids.each do |product|
      next if relations.map(&:product_id).include?product
      ProductLableRelation.new do |p|
        p.product_id = product
        p.product_lable_id = lable
        p.save
      end
    end
  end

  def destroy_lables(lable, product_ids, params)
    relations = ProductLableRelation.lable_filter(lable)
    product_ids = [] if product_ids.nil?
    relations.each do |relation|
      if product_ids.include?relation.product_id.to_s
        relation.number = params["number_update_column_#{relation.product_id}"].to_i unless params["number_update_column_#{relation.product_id}"].nil?
        relation.save
      else
        relation.destroy
      end
    end
  end

end
