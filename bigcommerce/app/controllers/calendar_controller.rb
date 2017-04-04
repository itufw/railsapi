require 'calendar_helper.rb'
class CalendarController < ApplicationController
  before_action :confirm_logged_in

  include CalendarHelper

  def redirect
    client = Signet::OAuth2::Client.new({
      client_id: Rails.application.secrets.google_client_id,
      client_secret: Rails.application.secrets.google_client_secret,
      authorization_uri: 'https://accounts.google.com/o/oauth2/auth',
      scope: Google::Apis::CalendarV3::AUTH_CALENDAR,
      redirect_uri: "http://localhost:3000/callback"
    })

    redirect_to client.authorization_uri.to_s
  end

  def callback
    client = Signet::OAuth2::Client.new({
      client_id: Rails.application.secrets.google_client_id,
      client_secret: Rails.application.secrets.google_client_secret,
      token_credential_uri: 'https://accounts.google.com/o/oauth2/token',
      redirect_uri: "http://localhost:3000/callback",
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
      @calendar_list = service.list_calendar_lists
      @event_list = []
      @calendar_list.items.each do |calendar|
        @event_list.append(service.list_events(calendar.id))
      end
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
    @colour_guide = ["purple", "violet", "red", "orange", "green", "lightgreen"]
    @colour_selected = colour_guide_filter(params["selected_colour"],@colour_guide)
    @order_colour_selected = colour_guide_filter(params["selected_order_colour"],@colour_guide)

    @customer_type = CustStyle.all

    # params["filter_selector"] = "Sales" || "Last_Order"
    case sales_last_order(params)
    when "Sales"
      colour_range = { "lightgreen" => [5000, 100000],
                       "green" => [3000,5000],
                       "orange"=> [1500,3000],
                       "red"   => [500, 1500],
                       "violet"=> [0,   500],
                       "purple"=> [0,0]
                     }
      # in Helper
      # filter customers with attributes
      @active_sales = true
      customer_map, @staff = customer_filter(params, @colour_selected, colour_range)
    when "Last_Order"
      colour_range = { "lightgreen" => [0, 15],
                       "green" => [15,30],
                       "orange"=> [30,45],
                       "red"   => [45,60],
                       "violet"=> [60,75],
                       "purple"=> [75,3000]
                     }
      @active_sales = false
      customer_map, @staff = customer_last_order_filter(params, @order_colour_selected, colour_range)
    end

    @hash = hash_map_pins(customer_map)
  end

end
