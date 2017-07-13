require 'google/apis/calendar_v3'
require 'googleauth'

module GoogleCalendarSync
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

  def calendar_event_update
    service = connect_google_calendar
    push_pending_events_to_google_offline(service)
    scrap_from_calendars(service)
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

  def scrap_from_calendars(service)
    new_events = []
    # record the events and the calendar id
    calendar_events_pair = {}
    unconfirmed_task = Task.unconfirmed_event.map(&:google_event_id)

    staff_calendars = StaffCalendarAddress.all

    service.list_calendar_lists.items.select { |x| staff_calendars.map(&:calendar_address).include?x.id }.each do |calendar|
      # only sync the tasks for last month
      items = service.list_events(calendar.id).items.select { |x| x.updated.to_s > (Date.today - 1.month).to_s }.select { |x| (x.start.date_time.to_s > (Date.today - 1.month).to_s) || (x.start.date.to_s > (Date.today - 1.month).to_s) }
      calendar_events_pair[calendar.id] = items.map(&:id)
      new_events += items
    end
    update_google_events(new_events, staff_calendars, unconfirmed_task, service, calendar_events_pair)
  end

  # scrap events from google calendar
  def update_google_events(new_events, staff_calendars, _unconfirm, service, calendar_events_pair)
    new_events.each do |event|
      task = Task.filter_by_google_event_id(event.id).first

      if !task.nil?
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
        task.description = event.summary
        task.location = event.location
        task.summary = event.description
        task.save
        # push address back to events
        update_event_location(task.task_relations.first, event, service, calendar_events_pair) if event.location.nil?

      else
        # filter the staff
        staff_address = staff_calendars.select { |x| [event.organizer.email, event.creator.email].include? x.calendar_address }.first
        next if staff_address.blank?
        Task.new.auto_insert_from_calendar_event(event, staff_address.staff_id)
      end
    end
  end

  def update_event_location(relation, event, service, calendar_events_pair)
    return if relation.nil?
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
end
