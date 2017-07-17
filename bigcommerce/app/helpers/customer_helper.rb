module CustomerHelper
  def customer_filter_path
    current_page?(action: 'incomplete_customers') ? 'incomplete_customers' : 'all'
  end

  def customer_type_name(customer)
    customer.cust_type.name unless customer.cust_type_id.nil?
  end

  def customer_style_name(customer)
    customer.cust_style.name unless customer.cust_style_id.nil?
  end

  def outstanding_customer(xero_contact)
    XeroContact.get_accounts_receivable_outstanding(xero_contact)
  end

  def overdue_customer(xero_contact)
    XeroContact.get_accounts_receivable_overdue(xero_contact)
  end

  def get_new_customers(params, customers, start_date, end_date)
    order_function, direction = sort_order(params, 'order_by_name', 'ASC')
    per_page = params[:per_page] || Customer.per_page
    customers = customers.filter_new_customer(start_date, end_date).include_all.send(order_function, direction).paginate(per_page: @per_page, page: params[:page])

    [per_page, customers]
  end

  def latest_orders(params, orders)
    order_function, direction = sort_order(params, :order_by_id, 'DESC')
    per_page = params[:per_page] || 5
    orders = orders.include_all.send(order_function, direction).paginate(per_page: per_page, page: params[:page])
    [orders, per_page]
  end

  def marks_by_distance(customers, leads, zomato_restaurants)
    # "<a href=\"http://188.166.243.138/customer/summary?customer_id=#{customer_id}&customer_name=#{customer_map[customer_id]["name"]}\">#{customer_map[customer_id]["name"]}</a>
    #                         <br/><br/>
    #                         <p>#{customer_map[customer_id]["infowindow"]}<p>"
    customer_hash = Gmaps4rails.build_markers(customers) do |customer, marker|
      marker.lat customer.lat
      marker.lng customer.lng
      marker.picture({
                        :url    => ActionView::Base.new.image_path('map_icons/bottle_shop_green.png'),
                        :width  => 30,
                        :height => 30
                       })
      marker.infowindow link_to "Customer:" + customer.actual_name, controller: 'customer', action: 'summary', customer_id: customer.id, customer_name: customer.actual_name
      marker.json ({
        :customer_id => customer.id,
        })
    end

    lead_hash = Gmaps4rails.build_markers(leads) do |lead, marker|
      marker.lat lead.latitude
      marker.lng lead.longitude
      marker.picture({
                        :url    => ActionView::Base.new.image_path('map_icons/lead_black.png'),
                        :width  => 30,
                        :height => 30
                       })
      marker.infowindow link_to "lead:" + lead.actual_name, controller: 'lead', action: 'summary', lead_id: lead.id
      marker.json ({
        :lead_id => lead.id,
        })
    end

    restaurant_hash = Gmaps4rails.build_markers(zomato_restaurants) do |restaurant, marker|
      marker.lat restaurant.latitude
      marker.lng restaurant.longitude
      marker.picture({
                        :url    => ActionView::Base.new.image_path('map_icons/zomato_white.png'),
                        :width  => 30,
                        :height => 30
                       })
      marker.infowindow "<a href=\"#{restaurant.url}\">#{restaurant.name}</a>
                                  <br/>
                                  <p>Average Cost: #{restaurant.average_cost_for_two}</p>
                                  <br/>
                                  <p>Zomato</p>"
    end
    [customer_hash, lead_hash, restaurant_hash]
  end

  def near_by_customers(latitude, longitude, radius, staff_id = nil)
    restaurants = ZomatoRestaurant.near([latitude, longitude], radius.to_f, units: :km).select{|x| x}
    customers = Customer.staff_search_filter(staff_id = staff_id).near([latitude, longitude], radius.to_f, units: :km).select{|x| x}
    leads = CustomerLead.filter_by_staff(staff_id).active_lead.near([latitude, longitude], radius.to_f, units: :km).select{|x| x}

    [customers, leads, restaurants]
  end
end
