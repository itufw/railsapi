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
    ZomatoRestaurant.all.each do |restaurant|
      customers_viewed += Customer.near([restaurant.latitude, restaurant.longitude], 0.8).map(&:id)
    end
    customers_viewed.uniq
  end

  def search_by_geo
    # MultiGeocoder.geocode(location)

    query = 'https://developers.zomato.com/api/v2.1/search?'
    customers_viewed = []
    customers = Customer.where('lng IS NOT NULL')

    # delete following block after data integrated
    customers_viewed = filter_viewed_spots
    customers = customers.select{ |x| !customers_viewed.include?x.id }


    while !customers.blank?
      customer = customers.first
      query += 'lat=' + customer.lat.to_s
      query += '&lon=' + customer.lng.to_s
      query += '&radius=' + '500'

      start = 0
      max_number = 300
      while start < max_number
        query += '&cuisines=' + get_cuisines.map(&:to_s).join('%2C%20')
        query += '&start=' + start.to_s
        response = HTTParty.get(query, headers: {"user-key" => Rails.application.secrets.zomato_key })
        break if response['restaurants'].nil? || response['restaurants'].blank? || (response['results_shown'] == 0)
        max_number = response['results_found']
        start = response['results_start'].to_i + 20
        restaurant_update_attribuets(response['restaurants'])
      end # end while

      customers_viewed += Customer.near([customer.lat, customer.lng], 0.5).map(&:id) if max_number < 100
      customers_viewed += Customer.near([customer.lat, customer.lng], 0.2).map(&:id) if max_number >= 100
      customers = customers.select{ |x| !customers_viewed.include?x.id }
    end
  end # end def

  def restaurant_update_attribuets(restaurants)
    restaurants.each do |restaurantL3|
      restaurant = restaurantL3['restaurant']
      next if restaurant.nil?
      next if ZomatoRestaurant.filter_by_id(restaurant['id']).count > 0

      restaurant_attr = {id: restaurant['id'], name: restaurant['name'],\
          url: restaurant['url'], address: restaurant['location']['address'],\
          locality: restaurant['location']['locality'],\
          latitude: restaurant['location']['latitude'],\
          longitude: restaurant['location']['longitude'],\
          zipcode: restaurant['location']['zipcode'],\
          country_id: restaurant['location']['country_id'],\
          average_cost_for_two: restaurant['average_cost_for_two'],\
          cuisines: restaurant['cuisines'] }
      ZomatoRestaurant.new().update_attributes(restaurant_attr)
    end # end resposne.each
  end

  private

  def get_cuisines
     [1,151,131,193,133,158,287,144,35,153,541,268,38,45,274,134,181,154,55,162,87,471,89,141,179,150,95,264]
  end
end
