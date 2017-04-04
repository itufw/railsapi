module CalendarHelper
  def sales_last_order(params)
    return "Last_Order" if ((params["filter_selector"].nil?) || ("".eql?params["filter_selector"]) ||  ("Last_Order".eql?params["filter_selector"]))
    return "Sales"
  end

  def map_filter(params, colour_guide, colour_range_origin)
    cust_type = params[:selected_cust_style] || []
    selected_staff = params[:selected_staff] || []

    colour_range = {}

    colour_guide.each do |colour|
      colour_range["#{colour}"] = (("".eql? params["order_range_#{colour}"]) || params["order_range_#{colour}"].nil? )? colour_range_origin["#{colour}"] : params["order_range_#{colour}"].split(",").map(&:to_i)
    end
    [cust_type, selected_staff, colour_range]
  end

  def colour_guide_filter(selected_colour, colour_guide)
    if selected_colour.nil?
      return colour_guide
    elsif selected_colour.blank?
      return colour_guide
    else
      return selected_colour
    end
  end

  def date_check_map(date,difference_month)
    if (date.nil?)|| ("".eql? date)
      return (Date.today()-difference_month.month).to_s(:db)
    else
      return date
    end
  end

  def add_map_pin(category, customer)
      case customer.cust_style_id
      when 1
        url = "map_icons/bottle_shop_#{category}.png"
      when 2
        url = "map_icons/restaurant_#{category}.png"
      else
        url = "map_icons/people_#{category}.png"
      end

      name = ""
      name += customer.firstname unless customer.firstname.nil?
      name += " "
      name += customer.lastname unless customer.lastname.nil?
      map_pin = {
        "name"=> name,
        "lat" => customer.lat,
        "lng" => customer.lng,
        "url" => url
      }
      map_pin
  end

  def customer_last_order_filter(params, colour_guide, colour_range_origin)
    selected_cust_style, selected_staff, colour_range = map_filter(params, colour_guide, colour_range_origin)
    start_date = date_check_map(params["start_time"], 0)
    end_date = date_check_map(params["due_time"], 0)

    customers = Customer.joins(:addresses).select("addresses.lat, addresses.lng, customers.*").where("addresses.lat IS NOT NULL").group("customers.id")
    customers = customers.joins(:orders).select("MAX(orders.date_created) as last_order_date, customers.id").order("orders.date_created DESC").group("customers.id")
    customers = customers.select{|x| selected_cust_style.include? x.cust_style_id.to_s } unless selected_cust_style.blank?
    customers = customers.select{|x| selected_staff.include? x.staff_id.to_s } unless selected_staff.blank?

    customer_map = {}
    start_date = (Date.parse start_date)

    customers.each do |customer|
      days_gap = (start_date - customer.last_order_date.to_date).to_i
      days_gap = 0 if days_gap < 0
      colour_range.keys.each do |colour|
        if days_gap.between?(colour_range["#{colour}"].min, colour_range["#{colour}"].max)
          customer_map[customer.id] = add_map_pin(colour, customer)
          break
        end #end if
      end #end colour guide for loop
    end #end customers for loop

    staff = Staff.filter_by_ids(customers.map{|x| x.staff_id}.uniq)
    [customer_map, staff]
  end


  def customer_filter(params, colour_guide, colour_range_origin)
    selected_cust_style, selected_staff, colour_range = map_filter(params, colour_guide, colour_range_origin)
    # default to one month ago until today
    start_date = date_check_map(params["start_time"], 3)
    end_date = date_check_map(params["due_time"], 0)

    customers = Customer.joins(:addresses).select("addresses.lat, addresses.lng, customers.*").where("addresses.lat IS NOT NULL").group("customers.id")

    # calculate the customers who have sales record in given period
    customers_sales = customers.joins(:orders).select("customers.id, sum(orders.total_inc_tax) as sales").where("orders.date_created < '#{end_date}' AND orders.date_created > '#{start_date}'").group("customers.id")
    customers_sales_ids = customers_sales.map{|x| x.id}

    customers = customers.select{|x| selected_cust_style.include? x.cust_style_id.to_s } unless selected_cust_style.blank?
    customers = customers.select{|x| selected_staff.include? x.staff_id.to_s } unless selected_staff.blank?


    customer_map = {}
    customers.each do |customer|
      order_amount = (customers_sales_ids.include? customer.id) ? customers_sales.find(customer.id).sales : 0

      colour_range.keys.each do |colour|
        if order_amount.between?(colour_range["#{colour}"].min, colour_range["#{colour}"].max)
          customer_map[customer.id] = add_map_pin(colour, customer)
          break
        end #end if
      end #end colour guide for loop
    end #end customers for loop

    staff = Staff.filter_by_ids(customers.map{|x| x.staff_id}.uniq)
    [customer_map, staff]
  end

  def hash_map_pins(customer_map)
    hash = Gmaps4rails.build_markers(customer_map.keys()) do |customer_id, marker|
      marker.lat customer_map[customer_id]["lat"]
      marker.lng customer_map[customer_id]["lng"]
      marker.picture({
                        :url    => view_context.image_path(customer_map[customer_id]["url"]),
                        :width  => 30,
                        :height => 30
                       })
            marker.infowindow "<a href=\"http://188.166.243.138/customer/summary?customer_id=#{customer_id}&customer_name=#{customer_map[customer_id]["name"]}\">#{customer_map[customer_id]["name"]}</a>"
      end
    hash
  end
end
