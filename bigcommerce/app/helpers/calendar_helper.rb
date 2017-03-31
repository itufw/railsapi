module CalendarHelper
  def map_filter(params, colour_guide)
    cust_type = params[:selected_cust_style] || []
    selected_staff = params[:selected_staff] || []

    colour_range = { "lightgreen" => [0, 0],
                     "green" => [0,500],
                     "orange"=> [500,1500],
                     "red"   => [1500,3000],
                     "violet"=> [3000,5000],
                     "purple"=> [5000,10000]
                   }
    colour_guide.each do |colour|
      colour_range["#{colour}"] = (("".eql? params["order_range_#{colour}"]) || params["order_range_#{colour}"].nil? )? colour_range["#{colour}"] : params["order_range_#{colour}"].split(",").map(&:to_i)
    end
    [cust_type, selected_staff, colour_range]
  end

  def customer_filter(params, colour_guide)
    selected_cust_style, selected_staff, colour_range = map_filter(params, colour_guide)
    start_date = params["start_time"] || (Date.today()-1.month).to_s(:db)
    end_date = params["due_time"] || Date.today().to_s(:db)

    customers = Customer.all
    customers = customers.select{|x| selected_cust_style.include? x.cust_type_id.to_s } unless selected_cust_style.blank?
    customers = customers.select{|x| selected_staff.include? x.staff_id.to_s } unless selected_staff.blank?

    customer_map = {}
    staff_ids = []
    category = ""
    customers.each do |customer|
      order_amount = customer.orders.select{|x| x.date_created < end_date && x.date_created>start_date}.map{|x| x.total_inc_tax}.sum
      colour_range.keys.each do |colour|
        if order_amount.between?(colour_range["#{colour}"].min, colour_range["#{colour}"].max)
          category = colour
          break
        end #end if
      end #end colour guide for loop

      unless "".eql? category
        # filter out the customers who do not have an address
        customer_add = customer.addresses.select{|x| x.lat.is_a? Numeric}
        next if customer_add.count == 0

        staff_ids.append(customer.staff_id)

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
          "lat" => customer_add.first.lat,
          "lng" => customer_add.first.lng,
          "url" => url
        }
        customer_map[customer.id] = map_pin
      end #end unless
    end #end customers for loop

    # customers = Customer.filter_by_ids(customer_map.keys())
    staff = Staff.filter_by_ids(staff_ids.uniq)
    [customer_map, staff, start_date, end_date]
  end
end
