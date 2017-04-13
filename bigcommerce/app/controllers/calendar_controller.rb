require 'calendar_helper.rb'
require 'models_filter.rb'

class CalendarController < ApplicationController
  before_action :confirm_logged_in

  include CalendarHelper
  include ModelsFilter

  def redirect
    uri = (Rails.env.development?) ? "http://localhost:3000/callback" : "http://188.166.243.138.xip.io/callback"
    client = Signet::OAuth2::Client.new({
      client_id: Rails.application.secrets.google_client_id,
      client_secret: Rails.application.secrets.google_client_secret,
      authorization_uri: 'https://accounts.google.com/o/oauth2/auth',
      scope: Google::Apis::CalendarV3::AUTH_CALENDAR,
      redirect_uri: uri
    })
    redirect_to client.authorization_uri.to_s
  end

  def callback
    uri = (Rails.env.development?) ? "http://localhost:3000/callback" : "http://188.166.243.138.xip.io/callback"

    client = Signet::OAuth2::Client.new({
      client_id: Rails.application.secrets.google_client_id,
      client_secret: Rails.application.secrets.google_client_secret,
      token_credential_uri: 'https://accounts.google.com/o/oauth2/token',
      redirect_uri: uri,
      code: params[:code]
    })

    response = client.fetch_access_token!

    session[:authorization] = response

    redirect_to calendars_url
  end

  def calendars
    client = Signet::OAuth2::Client.new({
      client_id: Rails.application.secrets.google_client_id,
      client_secret: Rails.application.secrets.google_client_secret,
      token_credential_uri: 'https://accounts.google.com/o/oauth2/token'
    })

    client.update!(session[:authorization])

    service = Google::Apis::CalendarV3::CalendarService.new
    service.authorization = client


    begin
      @current_user = Staff.filter_by_id(session[:user_id])
      @calendar_list = service.list_calendar_lists.items.select{|x| x.id.include?"@untappedwines.com" }
      @event_list = []
      @calendar_list.each do |calendar|
        @event_list.append(service.list_events(calendar.id))
      end
      p = c
    rescue Google::Apis::AuthorizationError => exception
      response = client.refresh!
      session[:authorization] = session[:authorization].merge(response)

      retry
    end

  end

  def new_event
    client = Signet::OAuth2::Client.new({
      client_id: Rails.application.secrets.google_client_id,
      client_secret: Rails.application.secrets.google_client_secret,
      token_credential_uri: 'https://accounts.google.com/o/oauth2/token'
    })

    client.update!(session[:authorization])

    service = Google::Apis::CalendarV3::CalendarService.new
    service.authorization = client

    today = Date.today

    event = Google::Apis::CalendarV3::Event.new({
      start: Google::Apis::CalendarV3::EventDateTime.new(date: today),
      end: Google::Apis::CalendarV3::EventDateTime.new(date: today + 1),
      summary: 'New event!'
    })

    service.insert_event(params[:calendar_id], event)

    redirect_to calendars_url
  end

  def map
    @colour_guide = ["lightgreen", "green", "gold", "coral", "red", "maroon"]

    @colour_selected = colour_guide_filter(params["selected_colour"],@colour_guide)
    @order_colour_selected = colour_guide_filter(params["selected_order_colour"],@colour_guide)

    @customer_type = CustStyle.all
    @customer_style_selected =  customer_style_filter(params[:selected_cust_style])

    @staff, @staff_selected = staff_filter(session, params[:selected_staff])

    @colour_range_sales = { "lightgreen" => [5000, 100000],
                     "green" => [3000,5000],
                     "gold"=> [1500,3000],
                     "coral"   => [500, 1500],
                     "red"=> [0,   500],
                     "maroon"=> [0,0]
                   }

    case sales_last_order(params)
    when "Sales"

      # in Helper
      # filter customers with attributes
      @active_sales = true
      customer_map, @start_date, @end_date = customer_filter_map(params, @colour_selected, @colour_range_sales, @customer_style_selected, @staff)
    when "Last_Order"
      colour_range = { "lightgreen" => [0, 15],
                       "green" => [15,30],
                       "gold"=> [30,45],
                       "coral"   => [45,60],
                       "red"=> [60,75],
                       "maroon"=> [75,3000]
                     }
      @active_sales = false
      customer_map, @start_date, @end_date = customer_last_order_filter(params, @order_colour_selected, colour_range, @customer_style_selected, @staff)
    end
    @hash = hash_map_pins(customer_map)

    # customer table
    order_function, direction = sort_order(params, 'order_by_name', 'ASC')
    @per_page = params[:per_page] || Customer.per_page
    @customers = Customer.filter_by_ids(customer_map.keys()).include_all.send(order_function, direction).paginate( per_page: @per_page, page: params[:page])

  end

end
