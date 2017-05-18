require 'models_filter.rb'
# lead Helper
module LeadHelper
  include ModelsFilter

  def lead_filter(params)
    search_text = params['search']
    cust_style_id, = collection_param_filter(params, :cust_style, CustStyle)
    staff_id, = collection_param_filter(params, :staff, Staff)

    leads = CustomerLead.search(search_text).filter_staff(staff_id).filter_cust_style(cust_style_id)

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

    staff = Staff.find(staff_id)

    client = GooglePlaces::Client.new('AIzaSyBvfTZH0XCVEJQTgR9QDYt18XIeV5MIkPI')
    spot = client.spots_by_query(customer_name + "near #{staff.state}", types: places_tags).first
    return nil if spot.nil?

    customer_lead.staff_id = staff_id
    customer_lead.actual_name = spot.name
    customer_lead.address = spot.formatted_address
    # default customer type to wholesale
    customer_lead.cust_type_id = 2
    if spot.types.include? ['bar']
      customer_lead.cust_style_id = 6
    elsif spot.types.include? ['liquor_store']
      customer_lead.cust_style_id = 1
    else
      customer_lead.cust_style_id = 2
    end

    spot
  end

  def places_tags
    %w[bar cafe casino liquor_store night_club restaurant shopping_mall store]
  end

end
