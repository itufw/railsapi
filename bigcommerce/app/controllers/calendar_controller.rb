require 'calendar_helper.rb'
require 'models_filter.rb'
require 'fuzzystringmatch'

class CalendarController < ApplicationController
    before_action :confirm_logged_in

    include CalendarHelper
    include ModelsFilter

    def redirect
        uri = Rails.env.development? ? 'http://localhost:3000/callback' : 'http://188.166.243.138.xip.io/callback'
        client = Signet::OAuth2::Client.new(client_id: Rails.application.secrets.google_client_id,
                                            client_secret: Rails.application.secrets.google_client_secret,
                                            authorization_uri: 'https://accounts.google.com/o/oauth2/auth',
                                            scope: Google::Apis::CalendarV3::AUTH_CALENDAR,
                                            :additional_parameters => {
                                              "access_type" => "offline",         # offline access
                                              "include_granted_scopes" => "true"  # incremental auth
                                            },
                                            redirect_uri: uri)
        redirect_to client.authorization_uri.to_s
    end

    def callback
        uri = Rails.env.development? ? 'http://localhost:3000/callback' : 'http://188.166.243.138.xip.io/callback'

        client = Signet::OAuth2::Client.new(client_id: Rails.application.secrets.google_client_id,
                                            client_secret: Rails.application.secrets.google_client_secret,
                                            token_credential_uri: 'https://accounts.google.com/o/oauth2/token',
                                            redirect_uri: uri,
                                            code: params[:code])
        response = client.fetch_access_token!

        session[:authorization] = response
        redirect_to calendars_url
    end

    def calendars
      # p = c
      # {"access_token"=>"ya29.GlszBOwNQ8VTGdG7I_8Svo6Iez-VADqUvC5AbxDpTVvo329xlzD0rwDyavPvFXKpZfvY2nLrNJKGFDzxQaOGvCY6S44nPcBPEQylTiwIPGwsHgB8pwN7D7R3aoxp", "expires_in"=>3600, "refresh_token"=>"1/t2PMHGM-8z_p733L_S_ZRhKU5nzDeArQqfZBFWrpQCA", "token_type"=>"Bearer"}
        client = Signet::OAuth2::Client.new(client_id: Rails.application.secrets.google_client_id,
                                            client_secret: Rails.application.secrets.google_client_secret,
                                            :additional_parameters => {
                                              "access_type" => "offline",         # offline access
                                              "include_granted_scopes" => "true"  # incremental auth
                                            },
                                            token_credential_uri: 'https://accounts.google.com/o/oauth2/token')
        client.update!(session[:authorization])
        service = Google::Apis::CalendarV3::CalendarService.new
        service.authorization = client
        begin
            @current_user = Staff.filter_by_id(session[:user_id])
            @calendar_list = service.list_calendar_lists.items.select { |x| x.id.include?'@untappedwines.com' }
            @event_list = []
            @calendar_list.each do |calendar|
                @event_list.append(service.list_events(calendar.id))
            end
        rescue Google::Apis::AuthorizationError => exception
            response = client.refresh!
            session[:authorization] = session[:authorization].merge(response)
            retry
        end
    end

    def event_censor
      client = Signet::OAuth2::Client.new(client_id: Rails.application.secrets.google_client_id,
                                          client_secret: Rails.application.secrets.google_client_secret,
                                          :additional_parameters => {
                                            "access_type" => "offline",         # offline access
                                            "include_granted_scopes" => "true"  # incremental auth
                                          },
                                          token_credential_uri: 'https://accounts.google.com/o/oauth2/token')
      client.update!(session[:authorization])
      service = Google::Apis::CalendarV3::CalendarService.new
      service.authorization = client

      begin
        @jarow = FuzzyStringMatch::JaroWinkler.create( :native)
        @customers = Customer.all.order_by_name("ASC")

        @methods = TaskMethod.all
        @subjects = TaskSubject.sales_subjects

        @events = Task.new.scrap_from_calendars(service)

        @staffs = Staff.filter_by_emails(@events.map{|x| x.creator.email}.uniq).active
      rescue Google::Apis::AuthorizationError => exception
          response = client.refresh!
          session[:authorization] = session[:authorization].merge(response)
          retry
      end
    end

    def translate_events
      if collection_valid_check(params)
        if Task.new.update_event(params["event_id"], params["method"], params["subject"], params["customer"])
          flash[:success] = "Done"
        else
          flash[:error] = "Something went wrong"
        end
      else
        flash[:error] = 'Select Right Customer/Method/Subject.'
      end
      redirect_to :back
    end

     def new_event
       #     client = Signet::OAuth2::Client.new(client_id: Rails.application.secrets.google_client_id,
    #                                         client_secret: Rails.application.secrets.google_client_secret,
    #                                         token_credential_uri: 'https://accounts.google.com/o/oauth2/token')
    #
    #     client.update!(session[:authorization])
    #
    #     service = Google::Apis::CalendarV3::CalendarService.new
    #     service.authorization = client
    #
    #     today = Date.today
    #
    #     customer_address = Address.where("customer_id = #{params[:customer_id]}").first
    #     address = combine_adress(customer_address)
    #
    #     event = Google::Apis::CalendarV3::Event.new(start: Google::Apis::CalendarV3::EventDateTime.new(date: today),
    #                                                 end: Google::Apis::CalendarV3::EventDateTime.new(date: today + 1),
    #                                                 summary: params[:description],
    #                                                 location: address,
    #                                                 attendees: Google::Apis::CalendarV3::EventAttendee.new(email: params[:staff_email]))
    #
    #     service.insert_event(params[:calendar_id], event)
    #
    #     redirect_to calendars_url
      end

    def map

        @colour_guide = %w(lightgreen green gold coral red maroon)

        @colour_selected = colour_guide_filter(params['selected_colour'], @colour_guide)
        @order_colour_selected = colour_guide_filter(params['selected_order_colour'], @colour_guide)

        @customer_type = CustStyle.all
        @customer_style_selected = customer_style_filter(params[:selected_cust_style])

        @staff, @staff_selected = staff_filter(session, params[:selected_staff])

        @max_date = ((params[:date_range_maroon])&&(params[:date_range_maroon].to_i.to_s.eql? params[:date_range_maroon]))? params[:date_range_maroon].to_i : 90
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
            colour_range = { 'lightgreen' => [0, 15],
                             'green' => [15, 30],
                             'gold' => [30, 45],
                             'coral' => [45, 60],
                             'red' => [60, 75],
                             'maroon' => [75, 3000] }
            @active_sales = false
            customer_map, @start_date, @end_date = customer_last_order_filter(params, @order_colour_selected, colour_range, @customer_style_selected, @staff)
        end
        @hash = hash_map_pins(customer_map)

        # customer table
        order_function, direction = sort_order(params, 'order_by_name', 'ASC')
        @per_page = params[:per_page] || Customer.per_page
        @customers = Customer.filter_by_ids(customer_map.keys).include_all.send(order_function, direction).paginate(per_page: @per_page, page: params[:page])
    end
end
