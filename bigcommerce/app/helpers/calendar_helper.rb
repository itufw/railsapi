module CalendarHelper
  def sales_last_order(params)
    return "Last_Order" if ((params["filter_selector"].nil?) || ("".eql?params["filter_selector"]) ||  ("Last_Order".eql?params["filter_selector"]))
    return "Sales"
  end

  def map_filter(params, colour_guide, colour_range_origin, sale_or_day)
    selected_staff = params[:selected_staff] || []

    colour_range = {}

    colour_guide.each do |colour|
      if sale_or_day
        colour_range["#{colour}"] = [params["order_range_#{colour}_min"].to_i, params["order_range_#{colour}_max"].to_i]
        # colour_range["#{colour}"] = (("".eql? params["order_range_#{colour}"]) || params["order_range_#{colour}"].nil? )? colour_range_origin["#{colour}"] : params["order_range_#{colour}"].split(",").map(&:to_i)
      else
        colour_range["#{colour}"] = (("".eql? params["date_range_#{colour}"]) || params["date_range_#{colour}"].nil? )? colour_range_origin["#{colour}"] : params["date_range_#{colour}"].split(",").map(&:to_i)
      end
      colour_range["#{colour}"].append(1000000) if colour_range["#{colour}"].length == 1
    end
    [selected_staff, colour_range]
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

  def customer_style_filter(customer_style_selected)
    default_style = ["1", "2"]
    if customer_style_selected.nil? || customer_style_selected.blank?
      return default_style
    else
      return customer_style_selected
    end
  end

  def staff_filter(session,staff_selected)
    staff = Staff.find(session[:user_id])
    if staff.user_type.in?(["Sales Executive"])
         return [[staff],[session[:user_id]]]
    end
    staff = Staff.active_sales_staff.order_by_order
    default_staff = []
    if staff_selected.nil? || staff_selected.blank?
      return [staff,default_staff]
    end
    [staff,staff_selected]
  end

  def date_check_map(date,difference_month)
    if (date.nil?)|| ("".eql? date)
      return (Date.today()-difference_month.month).to_s(:db)
    else
      return date
    end
  end

  def add_map_pin(category, customer, sale_or_day, func)
      case customer.cust_style_id
      when 1
        url = "map_icons/bottle_shop_#{category}.png"
      when 2
        url = "map_icons/restaurant_#{category}.png"
      else
        url = "map_icons/people_#{category}.png"
      end

      if customer.actual_name.nil?
        name = ""
        name += customer.firstname unless customer.firstname.nil?
        name += " "
        name += customer.lastname unless customer.lastname.nil?
      else
        name = customer.actual_name
      end

      case func
      when "Sales"
        infowindow = "Total Sales in this period: " + sale_or_day.to_s
      when "Last_Order"
        infowindow = "Last Order in : " + sale_or_day.to_s + "  days"
      end

      map_pin = {
        "name"=> name,
        "lat" => customer.lat,
        "lng" => customer.lng,
        "url" => url,
        "infowindow" => infowindow
      }
      map_pin
  end

  # filter customer based on the last orde date
  # default to the days started from today
  def customer_last_order_filter(params, colour_guide, colour_range_origin, selected_cust_style, staffs)
    selected_staff, colour_range = map_filter(params, colour_guide, colour_range_origin, false)
    start_date = (Date.parse date_check_map(params["start_time"], 0))
    end_date = (Date.parse date_check_map(params["due_time"], 0))

    customers = Customer.joins(:addresses).select("addresses.lat, addresses.lng, customers.*").where("addresses.lat IS NOT NULL AND customers.staff_id IN (?)", staffs.map{|x| x.id}).group("customers.id")
    # the Status check needs to be updated
    customers = customers.joins(:orders).select("MAX(orders.date_created) as last_order_date, customers.id").where("orders.status_id IN (2, 3, 7, 8, 9, 10, 11, 12, 13)").order("orders.date_created DESC").group("customers.id")
    customers = customers.select{|x| selected_cust_style.include? x.cust_style_id.to_s } unless selected_cust_style.blank?
    customers = customers.select{|x| selected_staff.include? x.staff_id.to_s } unless selected_staff.blank?

    customer_map = {}

    customers.each do |customer|
      days_gap = (start_date - customer.last_order_date.to_date).to_i
      days_gap = 0 if days_gap < 0
      colour_range.keys.each do |colour|
        if days_gap.between?(colour_range["#{colour}"].min, colour_range["#{colour}"].max)
          customer_map[customer.id] = add_map_pin(colour, customer, days_gap, "Last_Order")
          break
        end #end if
      end #end colour guide for loop
    end #end customers for loop

    [customer_map, start_date, end_date]
  end

  # filter customer based on the sales for givin period
  # default to pass 3 months
  def customer_filter_map(params, colour_guide, colour_range_origin, selected_cust_style, staffs)
    selected_staff, colour_range = map_filter(params, colour_guide, colour_range_origin, true)

    # default to one month ago until today
    start_date = (Date.parse date_check_map(params["start_time"], 3))
    end_date = (Date.parse date_check_map(params["due_time"], 0))

    customers = Customer.joins(:addresses).select("addresses.lat, addresses.lng, customers.*").where("addresses.lat IS NOT NULL AND customers.staff_id IN (?)", staffs.map{|x| x.id}).group("customers.id")

    # calculate the customers who have sales record in given period
    customers_sales = Customer.joins(:orders).select("customers.id, sum(orders.total_inc_tax) as sales").where("orders.status_id IN (2, 3, 7, 8, 9, 10, 11, 12, 13)").where("orders.date_created < '#{end_date}' AND orders.date_created > '#{start_date}'").group("customers.id")
    customers_sales_ids = customers_sales.map{|x| x.id}

    customers = customers.select{|x| selected_cust_style.include? x.cust_style_id.to_s } unless selected_cust_style.blank?
    customers = customers.select{|x| selected_staff.include? x.staff_id.to_s } unless selected_staff.blank?

    customer_map = {}
    customers.each do |customer|
      order_amount = (customers_sales_ids.include? customer.id) ? customers_sales.find(customer.id).sales : 0

      colour_range.keys.each do |colour|
        if order_amount.between?(colour_range["#{colour}"].min, colour_range["#{colour}"].max)
          customer_map[customer.id] = add_map_pin(colour, customer, order_amount, "Sales")
          break
        end #end if
      end #end colour guide for loop
    end #end customers for loop

    [customer_map, start_date, end_date]
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
            marker.infowindow "<a href=\"http://188.166.243.138/customer/summary?customer_id=#{customer_id}&customer_name=#{customer_map[customer_id]["name"]}\">#{customer_map[customer_id]["name"]}</a>
                              <br/><br/>
                              <p>#{customer_map[customer_id]["infowindow"]}<p>"
      end
    hash
  end

  def event_to_task(event_list)
    task_list = Task.where("google_event_id IS NOT NULL")
    task_google_event_ids = task_list.map{|x| x.google_event_id}
    event_list.each do |calendar_event|
      items = calendar_event.items.select{|x| !(task_google_event_ids.include? x.id)}
      items.each do |event|
        unless event.attendees.nil?

        end
      end
    end
  end


end
