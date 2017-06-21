module CalendarHelper

  def user_full_right(_authority)
    return true if %w[Admin Management Accounts].include? session[:authority]
    false
  end

  def sales_last_order(params)
    return 'Last_Order' if ((params["filter_selector"].nil?) || ("".eql?params["filter_selector"]) ||  ("Last_Order".eql?params["filter_selector"]))
    'Sales'
  end

  def map_filter(params, colour_guide, colour_range_origin, sale_or_day)
    selected_staff = params[:selected_staff] || []
    colour_range = {}
    colour_guide.each do |colour|
      # sale_or_day
      # false for Last order Date
      # true for sales
      colour_range[colour] = [params["order_range_#{colour}_min"].to_i, params["order_range_#{colour}_max"].to_i] if sale_or_day
      colour_range[colour] = (("".eql? params["date_range_#{colour}"]) || params["date_range_#{colour}"].nil? )? colour_range_origin["#{colour}"] : params["date_range_#{colour}"].split(",").map(&:to_i) if !sale_or_day
      colour_range[colour].append(1_000_000) if colour_range[colour].length == 1
    end
    [selected_staff, colour_range]
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
      return [[staff], [session[:user_id]]]
    end
    staff = Staff.active_sales_staff.order_by_order
    default_staff = []
    if staff_selected.nil? || staff_selected.blank?
      return [staff,default_staff]
    end
    [staff, staff_selected]
  end

  def add_map_pin(category, customer, infowindow)
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
      map_pin = {
        "name"=> name,
        "lat" => customer.latitude,
        "lng" => customer.longitude,
        "url" => url,
        "infowindow" => infowindow,
        "staff_id" => customer.staff_id
      }
      map_pin
  end

  # --------------------------------------
  # splited functions from map filter
  # return date -> for datepicker
  def date_check_map(date, difference, month = 'month')
    diff = 'month' == month ? difference.month : difference.days
    return (Date.today - diff).to_s(:db) if date.nil? || (''.eql? date)
    date
  end

  # return [start_date, end_date]
  def time_picker(params, difference, month = 'month')
    start_date = date_check_map(params['start_time'], difference, month)
    end_date = date_check_map(params['due_time'], difference, month)
    [(Date.parse start_date), (Date.parse end_date)]
  end

  # filter unselected colours out
  # [sales selected colour, orders selected colour, colour_guide, max_day]
  def colour_selected(params)
    colour_guide = %w[lightgreen green gold coral red maroon]
    sales = orders = colour_guide

    sales_s = params['selected_colour']
    orders_s = params['selected_order_colour']

    sales = sales_s unless sales_s.blank?
    orders = orders_s unless orders_s.blank?

    max_day = max_date(params[:date_range_maroon])
    [sales, orders, colour_guide, max_day]
  end

  # max_date for maroon
  def max_date(date)
    max = 90
    max = date.to_i if date.to_i.to_s == date
    max
  end

  def add_event_pin(customer, event, current_customer = true)
    name = (customer.actual_name.nil?) ? customer.firstname.to_s + ' ' + customer.lastname.to_s : customer.actual_name.to_s
    infowindow = event.description
    url = 'map_icons/daysofweek_' + event.start_date.strftime("%a").downcase.to_s + '_' + (current_customer ? 'yellow' : 'black') + '.png'
    map_pin = {
      'name' => name, 'lat' => customer.latitude, 'lng' => customer.longitude,
      'customer_id' => event.customer_id,
      'url' => url, 'infowindow' => infowindow,
      'date' => event.start_date, 'event_id' => event.google_event_id,
      'creator' => event.response_staff, 'participant' => event.staff_id
    }

    map_pin
  end

  # --------------------------------------
  # events are the tasks
  def calendar_filter(params, colour_guide, staffs, events)
    colour_range = {
      'lightgreen' => [0, 15], 'green' => [15, 30], 'gold' => [30, 45],
      'coral' => [45, 60], 'red' => [60, 75], 'maroon' => [75, 3000]
    }
    _, colour_range = map_filter(params, colour_guide, colour_range, false)
    start_date, end_date = time_picker(params, 0)
    customers = Customer.joins(:addresses).select("addresses.lat AS latitude, addresses.lng AS longitude, customers.*").where("addresses.lat IS NOT NULL AND (customers.staff_id IN (?) OR customers.id IN (?))", staffs.map(&:id), events.map(&:customer_id)).group("customers.id")
    customers = customers.joins(:orders).select("MAX(orders.date_created) as last_order_date, customers.id").where("orders.status_id IN (2, 3, 7, 8, 9, 10, 11, 12, 13)").order("orders.date_created DESC").group("customers.id")

    leads = CustomerLead.all
    # customer pins -> based on last order date
    customer_map = {}
    customers.each do |customer|
      days_gap = (start_date - customer.last_order_date.to_date).to_i
      days_gap = 0 if days_gap < 0
      colour_range.keys.each do |colour|
        if days_gap.between?(colour_range["#{colour}"].min, colour_range["#{colour}"].max)
          infowindow = "Last Order in : " + days_gap.to_s + "  days"
          customer_map[customer.id] = add_map_pin(colour, customer, infowindow)
          break
        end # end if
      end # end colour guide for loop
    end # end customers for loop

    event_map = {}
    events.each do |event|
      customer = customers.select { |x| x.id == event.customer_id }.first
      if !customer.nil?
        event_map[event.google_event_id] = add_event_pin(customer, event)
      else
        lead = leads.select { |x| x.id == event.customer_lead_id}.first
        event_map[event.google_event_id] = add_event_pin(lead, event, false) unless lead.nil?
      end
    end
    [customer_map, event_map, start_date, end_date]
  end

  def get_events_details(staff_id, start_date = nil, end_date = nil)
    start_date = Date.today - 1.month if start_date.nil?
    end_date = Date.today if end_date.nil?

    events = Task.joins(:task_relations).select('task_relations.*, tasks.*').where('tasks.start_date >= ? AND end_date <= ? AND tasks.google_event_id IS NOT NULL AND (task_relations.staff_id = ? OR tasks.response_staff = ? )', start_date.to_s, end_date.to_s, staff_id, staff_id)
    events
  end

  def get_customers_pins(staff_id, start_date = nil)
    customers = Customer.filter_by_staff(staff_id).joins(:addresses).select("addresses.lat AS latitude, addresses.lng AS longitude, customers.*").where("addresses.lat IS NOT NULL").group("customers.id")
    customers = customers.joins(:orders).select("MAX(orders.date_created) as last_order_date, customers.id").where("orders.status_id IN (2, 3, 7, 8, 9, 10, 11, 12, 13)").order("orders.date_created DESC").group("customers.id")

    start_date = Date.today if start_date.nil?
    colour_range = {
      'lightgreen' => [0, 15], 'green' => [15, 30], 'gold' => [30, 45],
      'coral' => [45, 60], 'red' => [60, 75], 'maroon' => [75, 3000]
    }

    customer_map = {}
    customers.each do |customer|
      days_gap = (start_date - customer.last_order_date.to_date).to_i
      days_gap = 0 if days_gap < 0
      colour_range.keys.each do |colour|
        if days_gap.between?(colour_range["#{colour}"].min, colour_range["#{colour}"].max)
          infowindow = "Last Order in : " + days_gap.to_s + "  days"
          customer_map[customer.id] = add_map_pin(colour, customer, infowindow)
          break
        end # end if
      end # end colour guide for loop
    end # end customers for loop

    customer_pins = hash_map_pins(customer_map)
    customer_pins
  end

  def get_events_pins(events)
    customers = Customer.filter_by_ids(events.map(&:customer_id).uniq.compact)
    customers = customers.joins(:addresses).select("addresses.lat AS latitude, addresses.lng AS longitude, customers.*") unless customers.nil?
    leads = CustomerLead.filter_by_ids(events.map(&:customer_lead_id).uniq.compact)

    event_map = {}
    events.each do |event|
      customer = (customers.nil?) ? nil : customers.select { |x| x.id == event.customer_id }.first
      if !customer.nil?
        event_map[event.google_event_id] = add_event_pin(customer, event)
      else
        lead = leads.select { |x| x.id == event.customer_lead_id}.first
        event_map[event.google_event_id] = add_event_pin(lead, event, false) unless lead.nil?
      end
    end
    event_hash = hash_event_pins(event_map)

    event_hash
  end

  # turn events to map_pins
  def hash_event_pins(event)
    hash = Gmaps4rails.build_markers(event.keys()) do |event_id, marker|
      marker.lat event[event_id]["lat"]
      marker.lng event[event_id]["lng"]
      marker.picture({ url: ActionView::Base.new.image_path(event[event_id]["url"]),
                        width: 30,
                        height: 30 })
      if event[event_id]['customer_id'].nil?
        marker.infowindow "</a>#{event[event_id]['name']}</a>
                                <br/><br/>
                                <p>#{event[event_id]['infowindow']}<p>"
      else
        marker.infowindow "<a href=\"http://188.166.243.138/customer/summary?customer_id=#{event[event_id]['customer_id']}&customer_name=#{event[event_id]['name']}\">#{event[event_id]['name']}</a>
                                <br/><br/>
                                <p>#{event[event_id]['infowindow']}<p>"
      end
      marker.json({
        date: event[event_id]['date'],
        participant: event[event_id]['participant'],
        creator: event[event_id]['creator']
        })
    end
    hash
  end

  # filter customer based on the last orde date
  # default to the days started from today
  def customer_last_order_filter(params, colour_guide, selected_cust_style, staffs)
    colour_range = {
      'lightgreen' => [0, 15], 'green' => [15, 30], 'gold' => [30, 45],
      'coral' => [45, 60], 'red' => [60, 75], 'maroon' => [75, 3000]
    }
    selected_staff, colour_range = map_filter(params, colour_guide, colour_range, false)
    start_date, end_date = time_picker(params, 0)

    customers = Customer.joins(:addresses).select("addresses.lat AS latitude, addresses.lng AS longitude, customers.*").where("addresses.lat IS NOT NULL AND customers.staff_id IN (?)", staffs.map{|x| x.id}).group("customers.id")
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
          infowindow = "Last Order in : " + days_gap.to_s + "  days"
          customer_map[customer.id] = add_map_pin(colour, customer, infowindow)
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
    start_date, end_date = time_picker(params, 3)

    customers = Customer.joins(:addresses).select("addresses.lat AS latitude, addresses.lng AS longitude, customers.*").where("addresses.lat IS NOT NULL AND customers.staff_id IN (?)", staffs.map{|x| x.id}).group("customers.id")

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
          infowindow = "Total Sales in this period: " + order_amount.to_s
          customer_map[customer.id] = add_map_pin(colour, customer, infowindow)
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
                        :url    => ActionView::Base.new.image_path(customer_map[customer_id]["url"]),
                        :width  => 30,
                        :height => 30
                       })
      marker.infowindow "<a href=\"http://188.166.243.138/customer/summary?customer_id=#{customer_id}&customer_name=#{customer_map[customer_id]["name"]}\">#{customer_map[customer_id]["name"]}</a>
                              <br/><br/>
                              <p>#{customer_map[customer_id]["infowindow"]}<p>"
      marker.json ({
        :customer_id => customer_id,
        :staff_id => customer_map[customer_id]['staff_id']
        })
      end
    hash
  end


  def collection_valid_check(params)
    ["customer","method","subject"].each do |column|
      if params[column]
        if ((params[column][column].nil?) || ("".eql? params[column][column]))
          return false
        end
      end
    end

  end

  def staff_access_token_update(user_session, authorization)
    return nil if authorization.nil?

    staff = Staff.find(user_session)
    staff.access_token = authorization["access_token"]
    if !(authorization["refresh_token"].nil?)
      staff.refresh_token = authorization["refresh_token"]
    elsif !(staff.refresh_token.nil?)
      authorization["refresh_token"] = staff.refresh_token
    end
    staff.save
    return authorization
  end

  # scrap events from google calendar
  def update_google_events(new_events, tasks, staff_calendars, unconfirm)
    new_events.select { |x| (!tasks.include?x.id) || (unconfirm.include?x.id) }.each do |event|
      if unconfirm.include? event.id
        task = Task.filter_by_google_event_id(event.id).first
        task.auto_update_from_calendar_event(event) unless task.nil?
      else
        # filter the staff
        staff_address = staff_calendars.select { |x| [event.organizer.email, event.creator.email].include? x.calendar_address}.first
        next if staff_address.blank?
        Task.new.auto_insert_from_calendar_event(event, staff_address.staff_id)
      end
    end
  end

  def scrap_from_calendars(service)
    new_events = []
    tasks = Task.where('google_event_id IS NOT NULL').map(&:google_event_id)
    unconfirmed_task = Task.unconfirmed_event.map(&:google_event_id)

    staff_calendars = StaffCalendarAddress.all
    service.list_calendar_lists.items.select { |x| staff_calendars.map(&:calendar_address).include?x.id }.each do |calendar|
      new_events += service.list_events(calendar.id).items
    end
    update_google_events(new_events, tasks, staff_calendars, unconfirmed_task)
  end

  # -----------------push events to google calendar ---------------------
  def push_pending_events_to_google
    client = Signet::OAuth2::Client.new(client_id: Rails.application.secrets.google_client_id,
                                        client_secret: Rails.application.secrets.google_client_secret,
                                        token_credential_uri: 'https://accounts.google.com/o/oauth2/token')

    client.update!(
      :additional_parameters => {"access_type" => "offline"}
      )
    client.update!(session[:authorization])

    service = Google::Apis::CalendarV3::CalendarService.new
    service.authorization = client

    tasks = Task.pending_event
    tasks.each do |t|
      t_relations = t.task_relations
      customer_id = t_relations.map(&:customer_id).compact
      customer_id = (customer_id.blank?) ? 0 : customer_id.first
      staff_ids = t_relations.map(&:staff_id).compact
      staff_ids.delete(0)
      next if staff_ids.blank?
      t.google_event_id = push_event(customer_id, t.description, staff_ids, t.response_staff, t.start_date, t.end_date, t.subject_1, t.method, service, client).id
      t.gcal_status = "pushed"
      t.save
    end
  end

  def combine_adress(customer_address)
    location = ""

    return location if customer_address.nil? || customer_address.blank?
    customer_address = customer_address.first

    location += customer_address.street_1 + " "
    location += customer_address.street_2 + " " unless customer_address.street_2.nil?
    location += ", " + customer_address.city + ", " + customer_address.state + ", " + customer_address.country
    location
  end

  # TODO
  # TODO
  # TODO
  # TODO
  def push_event(customer_id, description, staff_ids, response_staff, start_time, end_time, subject, method, service, client)

    staffs = Staff.filter_by_ids(staff_ids.append(response_staff))
    staff_calendar_addresses = StaffCalendarAddress.filter_by_ids(staff_ids)
    response_staff = staffs.select { |x| x.id.to_s == response_staff.to_s }.first
    response_staff_email = response_staff.email

    attendee_list = []
    staffs.each do |staff|
      attend = {
        displayName: staff.nickname,
        email: staff_calendar_addresses.select{|x|x.staff_id == staff.id}.first.calendar_address
      }
      attendee_list.append(attend)
    end

    customer = Customer.where("customers.id = #{customer_id}")
    customer = (customer.blank?) ? 'No Customer' : customer.first.actual_name

    address = combine_adress(Address.where("customer_id = #{customer_id}")) if customer_id != 0
    task_subject = TaskSubject.find(subject).subject

    event = Google::Apis::CalendarV3::Event.new({
                                                start: {
                                                  date_time: start_time.strftime('%Y-%m-%dT%H:%M:%S'),
                                                  time_zone: 'Australia/Melbourne',
                                                },
                                                end:{
                                                  date_time: end_time.strftime('%Y-%m-%dT%H:%M:%S'),
                                                  time_zone: 'Australia/Melbourne',
                                                },
                                                # colorID: "2",
                                                summary: customer,
                                                description: task_subject + ": "+ customer + "\n" +description + "\n Created By:" + response_staff.nickname,
                                                location: address,
                                                attendees: attendee_list
                                                })
    begin
      gcal_event = service.insert_event('primary', event, send_notifications: true)
      return gcal_event
    rescue Google::Apis::AuthorizationError
      client.update!(
        additional_parameters: {
          grant_type: 'refresh_token'
        }
      )
      response = client.refresh!
      session[:authorization] = session[:authorization].merge(response)
      retry
    end
  end
end
