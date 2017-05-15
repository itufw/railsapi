require 'calendar_helper.rb'
require 'models_filter.rb'
require 'fuzzystringmatch'

class CalendarController < ApplicationController

  skip_before_action :verify_authenticity_token
  before_action :confirm_logged_in
  include CalendarHelper
  include ModelsFilter

  def redirect
    uri = Rails.env.development? ? 'http://localhost:3000/callback' : 'http://188.166.243.138.xip.io/callback'
    client = Signet::OAuth2::Client.new(
      client_id: Rails.application.secrets.google_client_id,
      client_secret: Rails.application.secrets.google_client_secret,
      authorization_uri: 'https://accounts.google.com/o/oauth2/auth',
      scope: Google::Apis::CalendarV3::AUTH_CALENDAR,
      additional_parameters: {
        access_type: 'offline', # offline access
        include_granted_scopes: true # incremental auth
      },
      redirect_uri: uri
    )
    redirect_to client.authorization_uri.to_s, event: params[:event]
  end

  def callback
    uri = Rails.env.development? ? 'http://localhost:3000/callback' : 'http://188.166.243.138.xip.io/callback'

    client = Signet::OAuth2::Client.new(
      client_id: Rails.application.secrets.google_client_id,
      client_secret: Rails.application.secrets.google_client_secret,
      token_credential_uri: 'https://accounts.google.com/o/oauth2/token',
      redirect_uri: uri,
      code: params[:code]
    )
    response = client.fetch_access_token!

    session[:authorization] = staff_access_token_update(session[:user_id], response)
    if params[:event]
      redirect_to controller: 'task', action: 'add_task'
    else
      redirect_to action: 'event_censor'
    end
  end

  def calendars
    # Token for one time only authorization
    # {"token_type"=>"Bearer"}
    client = Signet::OAuth2::Client.new(
      client_id: Rails.application.secrets.google_client_id,
      client_secret: Rails.application.secrets.google_client_secret,
      additional_parameters: {
        access_type: 'offline', # offline access
        include_granted_scopes: true # incremental auth
      },
      token_credential_uri: 'https://accounts.google.com/o/oauth2/token'
    )
    client.update!(session[:authorization])
    service = Google::Apis::CalendarV3::CalendarService.new
    service.authorization = client
    begin
      @staffs = Staff.active
      @current_user = @staffs.select { |x| x.id == session[:user_id] }.first

      staff_event = {}
      @calendar_list = []
      tasks = Task.joins(:task_relations).select('task_relations.customer_id, tasks.google_event_id, tasks.start_date, tasks.end_date, tasks.description').where('tasks.google_event_id IS NOT NULL')
      service.list_calendar_lists.items.each do |calendar|
        calendar_staff = @staffs.select { |x| x.email == calendar.id }
        next unless calendar_staff.count > 0

        calendar_staff = calendar_staff.first
        staff_event[calendar_staff.id] = \
          service.list_events(calendar.id).items.map(&:id)
        @calendar_list.append(calendar)
      end
      @event_customers = {}
      @tasks = []
      staff_event.keys.each do |staff|
        temp_task = tasks.select { |x| staff_event[staff].include?x.google_event_id }
        @tasks += temp_task
        @event_customers[staff] = \
          temp_task.map(&:customer_id).uniq
      end

      @customers = Customer.all
      _, @order_colour_selected, @colour_guide, @max_date =
        colour_selected(params)

      staff, = staff_filter(session, params[:selected_staff])
      customer_map, @start_date, @end_date = customer_last_order_filter(\
        params, @order_colour_selected, [], staff
      )
      @hash = hash_map_pins(customer_map)
      flash[:error] = 'Please Log in as untapped google account and try again' \
        if @calendar_list.blank?
    rescue Google::Apis::AuthorizationError
      response = client.refresh!
      session[:authorization] = session[:authorization].merge(response)
      retry
    end
  end

  def local_calendar
    @calendar_date = params[:calendar_date_selected]
    @calendar_staff = params[:calendar_staff_selected]

    @current_user = Staff.find(session[:user_id])
    # tempary use, it should be assigned based on the current users' right
    if session[:user_id] == 18
      @staffs = Staff.where('staffs.id IN (?)', [18])
    else
      @staffs = Staff.where('staffs.id IN (?)', [9, 36, 18])
    end
    # @staffs = Staff.active
    @events = Task.joins(:task_relations).select('task_relations.*, tasks.*').where('tasks.google_event_id IS NOT NULL AND (task_relations.staff_id IN (?) OR tasks.response_staff IN (?))', @staffs.map(&:id), @staffs.map(&:id))

    @customers = Customer.all
    _, @order_colour_selected, @colour_guide, @max_date =
      colour_selected(params)
    customer_map, event_map, @start_date, @end_date = \
      calendar_filter(params, @order_colour_selected, @staffs, @events)

    @hash = hash_map_pins(customer_map)
    @event_hash = hash_event_pins(event_map)
    params[:start_date] = params[:start_date] || Date.current.beginning_of_month.to_s
    @current_month = (Date.parse params[:start_date]).beginning_of_month
  end

  def event_censor
    client = Signet::OAuth2::Client.new(client_id: Rails.application.secrets.google_client_id,
                                        client_secret: Rails.application.secrets.google_client_secret,
                                        additional_parameters: {
                                          'access_type' => 'offline',         # offline access
                                          'include_granted_scopes' => 'true'  # incremental auth
                                        },
                                        token_credential_uri: 'https://accounts.google.com/o/oauth2/token')
    client.update!(session[:authorization])
    service = Google::Apis::CalendarV3::CalendarService.new
    service.authorization = client

    begin
      @jarow = FuzzyStringMatch::JaroWinkler.create(:native)
      @customers = Customer.all.order_by_name('ASC')
      @leads = CustomerLead.all.order_by_name('ASC')

      @methods = TaskMethod.all
      @subjects = TaskSubject.sales_subjects

      @events = Task.new.scrap_from_calendars(service)

      @staffs = Staff.filter_by_emails(@events.map { |x| x.creator.email }.uniq).active
    rescue Google::Apis::AuthorizationError
      begin
        response = client.refresh!
      rescue
        redirect_to action: redirect && return
      end
      session[:authorization] = session[:authorization].merge(response)
      retry

    end
  end

  # handle the requests for updating events
  def translate_events
    if params['submit'] == 'reject'
      Task.new.reject_event(params['event_id'])
      redirect_to action: 'event_censor'
      return
    end

    if collection_valid_check(params)
      if Task.new.update_event(params['event_id'], params['method'], params['subject'], params['customer'])
        flash[:success] = 'Done'
      else
        flash[:error] = 'Something went wrong'
      end
    else
      flash[:error] = 'Select Right Customer/Method/Subject.'
    end
    redirect_to :back
  end

  def map
    @colour_selected, @order_colour_selected, @colour_guide, @max_date =
      colour_selected(params)

    @customer_type = CustStyle.all
    @customer_style_selected =
      customer_style_filter(params[:selected_cust_style])

    @staff, @staff_selected =
      staff_filter(session, params[:selected_staff])

    @colour_range_sales = { 'lightgreen' => [5000, 100_000],
                            'green' => [3000, 5000],
                            'gold' => [1500, 3000],
                            'coral' => [500, 1500],
                            'red' => [0, 500],
                            'maroon' => [0, 0] }

    case sales_last_order(params)
    when 'Sales'

      # in Helper
      # filter customers with attributes
      @active_sales = true
      customer_map, @start_date, @end_date = customer_filter_map(params, @colour_selected, @colour_range_sales, @customer_style_selected, @staff)
    when 'Last_Order'
      @active_sales = false
      customer_map, @start_date, @end_date = customer_last_order_filter(params, @order_colour_selected, @customer_style_selected, @staff)
    end
    @hash = hash_map_pins(customer_map)

    # customer table
    order_function, direction = sort_order(params, 'order_by_name', 'ASC')
    @per_page = params[:per_page] || Customer.per_page
    @customers = Customer.filter_by_ids(customer_map.keys).include_all.send(order_function, direction).paginate(per_page: @per_page, page: params[:page])
  end
end
