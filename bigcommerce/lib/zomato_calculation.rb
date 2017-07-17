# import from zomato
module ZomatoCalculation

  def zomato
    "https://developers.zomato.com/api/v2.1/search?entity_id=259&entity_type=city&start=50"

    entity_id = 259
    entity_type = 'city'
    blank_space = '%2C%20'
    start = 50
    lat = 'lat=' + '-37.8136'

    query = 'entity_id=' + entity_id.to_s
    query += '&entity_type' + entity_type.to_s
    query += '&cuisines=' + get_cuisines.map(&:to_s).joins('%2C%20')
    response = HTTParty.get('https://developers.zomato.com/api/v2.1/search?entity_id=259&entity_type=city&cuisines=1%2C%20151%2C%203%2C%20131%2C%20193%2C%20133%2C%20158%2C%20287%2C%20144%2C%2035%2C%20153%2C%20541%2C%20268%2C%2038%2C%2045%2C%20274%2C%20134%2C%20181%2C%20154%2C%2055%2C%20162%2C%2087%2C%20471%2C%2089%2C%20141%2C%20179%2C%20150%2C%2095%2C%20264', headers: {"user-key" =>'210cbff82e3ecf757c6914794e1ca953' })
  end

  def filter_viewed_spots
    customers_viewed = []
    restaurants = ZomatoRestaurant.all
    while !restaurants.blank?
      customers_viewed += Customer.near([restaurants.first.latitude, restaurants.first.longitude], 0.1, units: :km).map(&:id)
      restaurants -= ZomatoRestaurant.near([restaurants.first.latitude, restaurants.first.longitude], 0.1, units: :km)
    end
    customers_viewed.uniq
  end

  def search_by_geo
    # MultiGeocoder.geocode(location)
    count_ping = 0
    query = 'https://developers.zomato.com/api/v2.1/search'
    customers_viewed = []
    customers = Customer.where('lng IS NOT NULL').select{ |x| x}

    # delete following block after data integrated
    # customers_viewed = filter_viewed_spots
    # customers = customers.select{ |x| !customers_viewed.include?x.id }
    # ------------------------------------------------------------------

    while !customers.blank?
      customer = customers.delete_at(customers.length - 1)

      start = 0
      results_found = 100
      while (results_found > 40) && ((start * 20) < results_found) && start < 80
        break if ZomatoRestaurant.near([customer.lat, customer.lng], 0.1, units: :km).map(&:id).count > 20
        response = HTTParty.get(query, query: {lat: customer.lat, lon: customer.lng, radius: 200, cuisines: get_cuisines.map(&:to_s), start: start}, headers: {"user-key" => Rails.application.secrets.zomato_key })
        start += 20
        count_ping += 1
        results_found = response['results_found'].to_i
        restaurant_update_attribuets(response['restaurants'])
        puts 'Counting ' + count_ping.to_s if count_ping % 10 == 0
      end
      return if count_ping > 800

      customers_viewed += Customer.near([customer.lat, customer.lng], 0.1, units: :km).map(&:id)
      customers = customers.select{ |x| !customers_viewed.include?x.id }
    end
  end # end def

  def restaurant_update_attribuets(restaurants)
    return if restaurants.nil? || restaurants.blank?
    restaurants.each do |restaurantL3|
      restaurant = restaurantL3['restaurant']
      next if restaurant.nil?
      next if (ZomatoCuisine.inactive_cuisines.map(&:name) + restaurant['cuisines'].split).sort.uniq == ZomatoCuisine.inactive_cuisines.map(&:name).sort.uniq
      next if ZomatoRestaurant.filter_by_id(restaurant['id']).count > 0

      customer = Customer.where('Round(lat, 4) = ? AND Round(lng, 3) = ? AND actual_name LIKE ?', restaurant['location']['latitude'].to_f.round(4), restaurant['location']['longitude'].to_f.round(3), restaurant['name']).first
      customer_id = (customer.nil?) ? nil : customer.id
      lead = CustomerLead.where('Round(latitude, 4) = ? AND Round(longitude, 3) = ? AND actual_name LIKE ?', restaurant['location']['latitude'].to_f.round(4), restaurant['location']['longitude'].to_f.round(3), restaurant['name']).first
      lead_id = (lead.nil?) ? nil : lead.id

      restaurant_attr = {id: restaurant['id'], name: restaurant['name'],\
          url: restaurant['url'], address: restaurant['location']['address'],\
          locality: restaurant['location']['locality'],\
          latitude: restaurant['location']['latitude'],\
          longitude: restaurant['location']['longitude'],\
          zipcode: restaurant['location']['zipcode'],\
          country_id: restaurant['location']['country_id'],\
          average_cost_for_two: restaurant['average_cost_for_two'],\
          cuisines: restaurant['cuisines'], active: 1,\
          customer_id: customer_id, customer_lead_id: lead_id
         }
      ZomatoRestaurant.new().update_attributes(restaurant_attr)
    end # end response.each
  end

  def update_customer_or_lead_for_zomato
    ZomatoRestaurant.where('customer_id IS NULL AND customer_lead_id IS NULL').each do |restaurant|
      customer = Customer.where('Round(lat, 4) = ? AND Round(lng, 3) = ? AND actual_name LIKE ?', restaurant.latitude.to_f.round(4), restaurant.longitude.to_f.round(3), restaurant.name).first
      restaurant.customer_id = (customer.nil?) ? nil : customer.id
      lead = CustomerLead.where('Round(latitude, 4) = ? AND Round(longitude, 3) = ? AND actual_name LIKE ?', restaurant.latitude.to_f.round(4), restaurant.longitude.to_f.round(3), restaurant.name).first
      restaurant.customer_lead_id = (lead.nil?) ? nil : lead.id
      restaurant.save if !restaurant.customer_id.nil? || !restaurant.customer_lead_id.nil?
    end
  end

  private

  def get_cuisines
    ZomatoCuisine.active_cuisines.map(&:id)
    #  [1,151,131,193,133,158,287,144,35,153,541,268,38,45,274,134,181,154,55,162,87,471,89,141,179,150,95,264]
  end
end
