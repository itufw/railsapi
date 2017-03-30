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
    selected_cust_type, selected_staff = map_filter(params)

    customers = Customer.all

    customers = customers.select{|x| x.updated_at > '2017-03-01'}

    customers = customers.select{|x| selected_cust_type.include? x.cust_type_id.to_s } unless selected_cust_type.blank?
    customers = customers.select{|x| selected_staff.include? x.staff_id.to_s } unless selected_staff.blank?

    customer_address = Address.has_lat_lng.group_by_customer.where("customer_id IN (?)", customers.map{|x| x.id})

    @staff = customer_address.map{|x| x.customer.staff}.uniq
    @customer_type = CustType.all

    @hash = Gmaps4rails.build_markers(customer_address) do |customer, marker|
      marker.lat customer.lat
      marker.lng customer.lng
      case customer.customer.cust_type_id
      when 1
        marker.picture({
                        :url    => view_context.image_path("map_icons/people.png"),
                        :width  => 30,
                        :height => 30
                       })
      when 2
        marker.picture({
                        :url    => view_context.image_path("map_icons/winebar.png"),
                        :width  => 30,
                        :height => 30
                       })
      else
        marker.picture({
                        :url    => view_context.image_path("map_icons/townhouse.png"),
                        :width  => 30,
                        :height => 30
                       })
      end
      marker.infowindow "<a href=\"http://188.166.243.138/customer/summary?customer_id=#{customer.customer_id}&customer_name=#{customer.firstname}+#{customer.lastname}\">#{customer.firstname} #{customer.lastname}</a>"

      end

  end

end
