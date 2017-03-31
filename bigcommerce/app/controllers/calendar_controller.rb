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
    @colour_guide = ["lightgreen","green","orange","red","violet", "purple"]
    # in Helper
    # filter customers with attributes
    customer_map, @staff, @start_date, @end_date = customer_filter(params, @colour_guide)

    @customer_type = CustStyle.all

    @hash = Gmaps4rails.build_markers(customer_map.keys()) do |customer_id, marker|
      marker.lat customer_map[customer_id]["lat"]
      marker.lng customer_map[customer_id]["lng"]
      marker.picture({
                        :url    => view_context.image_path(customer_map[customer_id]["url"]),
                        :width  => 30,
                        :height => 30
                       })
            marker.infowindow "<a href=\"http://188.166.243.138/customer/summary?customer_id=#{customer_id}&customer_name=#{customer_map[customer_id]["name"]}\">#{customer_map[customer_id]["name"]}</a>"
      end

  end

end
