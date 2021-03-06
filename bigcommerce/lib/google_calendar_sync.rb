require 'google/apis/calendar_v3'
require 'googleauth'

module GoogleCalendarSync

  def import_into_customer_tags
    active_sales_staff = Staff.active_sales_staff.map(&:id)
    active_sales_staff.delete(24)
    active_sales_staff.delete(34)

    exist_customer = CustomerTag.filter_by_role('Customer').map(&:customer_id)
    Customer.where('id NOT IN (?)', exist_customer).staff_filter(active_sales_staff).where('actual_name IS NOT NULL').each do |customer|
      CustomerTag.new.insert_customer(customer)
    end

    exist_lead = CustomerTag.filter_by_role('Lead').map(&:customer_id)
    CustomerLead.where('id NOT IN (?)', exist_lead).where('customer_id IS NULL').each do |lead|
      CustomerTag.new.insert_lead(lead)
    end

    exist_contact = CustomerTag.filter_by_role('Contact').map(&:customer_id)
    Contact.sales_force.where('id NOT IN (?)', exist_contact).each do |contact|
      CustomerTag.new.insert_contact(contact)
    end

    customer_state_update
  end

  def customer_state_update
    states = ['VIC', 'TAS', 'QLD', 'WA', 'SA', 'NT', 'NSW', 'ACT']
    Customer.where('lat IS NOT NULL AND country = \'Australia\' AND state NOT IN (?)', states).each do |customer|
      begin
        state = customer.address.split(',')[-2].split()[-2]
        customer.state = state if states.include? state
        customer.save
      rescue
        next
      end
    end
  end

  def connect_google_calendar
    ENV['GOOGLE_APPLICATION_CREDENTIALS'] = 'config/key.json'

    scopes = 'https://www.googleapis.com/auth/calendar'
    authorization = Google::Auth.get_application_default(scopes)
    # authorization = Google::Auth.get_application_default(scopes).dup

    service = Google::Apis::CalendarV3::CalendarService.new
    service.authorization = authorization
    service.authorization.fetch_access_token!
    service
  end

  def calendar_event_update(last_update_date = (Time.now - 1.month), staff_calendars = StaffCalendarAddress.all)
    service = connect_google_calendar
    push_pending_events_to_google_offline(service)
    scrap_from_calendars(service, last_update_date, staff_calendars)
  end

  def push_pending_events_to_google_offline(service)
    tasks = Task.pending_event
    tasks.each do |t|
      t_relations = t.task_relations
      customer = nil
      customer = Customer.find(t_relations.map(&:customer_id).compact.first) if t_relations.map(&:customer_id).compact.first.to_i != 0
      customer = CustomerLead.find(t_relations.map(&:customer_lead_id).compact.first.to_i) if customer.nil? && t_relations.map(&:customer_lead_id).compact.first.to_i != 0
      staff_ids = t_relations.map(&:staff_id).compact
      staff_ids.delete(0)
      next if staff_ids.blank?
      t.google_event_id = push_event(customer, t.description, staff_ids, t.response_staff, t.start_date, t.end_date, t.subject_1, t.method, service, service.authorization).id
      t.gcal_status = 'pushed'
      t.save
    end
  end

  def scrap_from_calendars(service, last_update_date, staff_calendars)
    new_events = []
    # record the events and the calendar id
    calendar_events_pair = {}

    service.list_calendar_lists.items.select { |x| staff_calendars.map(&:calendar_address).include?x.id }.each do |calendar|
      # only sync the tasks for last month
      items = service.list_events(calendar.id, updated_min: last_update_date.to_datetime.rfc3339, show_deleted: false).items
      calendar_events_pair[calendar.id] = items.map(&:id)
      new_events += items
    end
    update_google_events(new_events, staff_calendars, service, calendar_events_pair)
  end

  # scrap events from google calendar
  def update_google_events(new_events, staff_calendars, service, calendar_events_pair)
    new_events.each do |event|
      # filter out the invalid events
      # Cancelled events
      next if event.created.nil?

      task = Task.filter_by_google_event_id(event.id).first

      # insert new task
      if task.nil?
        # filter the staff
        staff_address = staff_calendars.select { |x| [event.organizer.email, event.creator.email].include? x.calendar_address }.first
        next if staff_address.blank?
        Task.new.auto_insert_from_calendar_event(event, staff_address.staff_id)
        # if events are updated, update the data
      elsif event.updated > task.updated_at
        task.start_date = if event.start.date_time.nil?
                            event.start.date.to_s
                          else
                            event.start.date_time.to_s(:db)
                          end
        task.end_date = if event.end.date_time.nil?
                          event.end.date.to_s
                        else
                          event.end.date_time.to_s(:db)
                        end
        task.summary = event.summary
        task.location = event.location
        task.description = event.description
        task.save
      else
        if event.location.nil? && !task.task_relations.first.nil?
          # push address back to events
          update_event_location(task.task_relations.first, event, service, calendar_events_pair)
        end
        if task.description != event.summary && task.description != event.description
          update_event_summary(task, event, service, calendar_events_pair)
        end
      end
    end
  end

  # Testing this one
  def update_event_summary(task, event, service, calendar_events_pair)
    event.description = task.description
    calendar_id = calendar_events_pair.select { |_key, value| value.include?event.id }.keys.first.to_s
    return if calendar_id == ''

    begin
      service.update_event(calendar_id, event.id, event)
    rescue
    end
  end

  def update_event_location(relation, event, service, calendar_events_pair)
    address = nil
    address = relation.customer.address unless relation.customer.nil?
    address = relation.customer_lead.address unless !address.nil? || relation.customer_lead.nil?

    return if address.nil?
    calendar_id = calendar_events_pair.select { |_key, value| value.include?event.id }.keys.first.to_s
    return if calendar_id == ''
    begin
      event.location = address
      service.update_event(calendar_id, event.id, event)
    rescue
    end
  end

  def push_event(customer, description, staff_ids, response_staff, start_time, end_time, subject, method, service, client)

    staffs = Staff.filter_by_ids(staff_ids.append(response_staff))
    staff_calendar_addresses = StaffCalendarAddress.filter_by_ids(staff_ids + staffs.map(&:id))
    response_staff = staffs.select { |x| x.id.to_s == response_staff.to_s }.first
    response_staff_email = response_staff.email

    attendee_list = []
    staffs.each do |staff|
      calendar_email = staff_calendar_addresses.select{|x|x.staff_id == staff.id}.first
      calendar_email = (calendar_email.nil?) ? staff.email : calendar_email.calendar_address
      next if calendar_email.nil?
      attend = {
        displayName: staff.nickname,
        email: calendar_email
      }
      attendee_list.append(attend)
    end

    customer_name = (customer.nil?) ? 'No Customer' : customer.actual_name
    address = customer.address unless customer.nil?

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
                                                summary: customer_name,
                                                description: task_subject + ": "+ customer_name + "\n" +description + "\n Created By:" + response_staff.nickname,
                                                location: address,
                                                attendees: attendee_list
                                                })
    begin
      gcal_event = service.insert_event('primary', event, send_notifications: true)
    rescue
    end

    return gcal_event
  end
end
