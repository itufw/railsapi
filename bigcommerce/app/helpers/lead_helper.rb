require 'models_filter.rb'
# lead Helper
module LeadHelper
  include ModelsFilter

  def lead_filter(params, per_page)
    search_text = params['search']
    cust_style_id, = collection_param_filter(params, :cust_style, CustStyle)
    staff_id, = collection_param_filter(params, :staff, Staff)

    order_function = params[:order_col] || 'order_by_name'
    direction = params[:direction] == '1' ? 'DESC' : 'ASC'

    leads = CustomerLead.search_for(search_text).filter_staff(staff_id).filter_cust_style(cust_style_id).send(order_function, direction).paginate( per_page: per_page, page: params[:page])

    [leads, search_text]
  end

  def lead_type_name(lead)
    return 'Region' unless lead.region.nil? || lead.region == ''
    'Customer'
  end

  def lead_address(lead)
    return lead.address if lead.region.nil? || lead.region == ''
    lead.address.split(',')[1, lead.address.length].join(',')
  end

  # get information from google places api
  def grab_from_google(params, customer_lead)
    customer_name = params['customer_name']
    staff_id = params['staff_id']
    return nil if customer_name.nil? || staff_id.nil?

    client = GooglePlaces::Client.new('AIzaSyBvfTZH0XCVEJQTgR9QDYt18XIeV5MIkPI')
    staff = Staff.find(staff_id)
    spots = client.spots_by_query(customer_name + "near #{staff.state}")

    customer_lead.staff_id = staff_id
    customer_lead.cust_type_id = 2
    # detailed spot
    [client, spots]
  end

  def places_tags
    %w[bar cafe liquor_store night_club restaurant shopping_mall store]
  end

  def spot_style(spot_types)
    return 6 if spot_types.include? 'bar'
    return 1 if spot_types.include? 'liquor_store'
    2
  end

  def spot_details(client, customer_lead, spot)
    place = client.spot(spot.place_id)

    customer_lead.phone = place.formatted_phone_number
    customer_lead.actual_name = place.name
    customer_lead.address = place.formatted_address
    customer_lead.website = place.website
    customer_lead.cust_style_id = spot_style(spot.types)

    place
  end
end
