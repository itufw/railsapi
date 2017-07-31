# import from zomato
module ZomatoCalculation

  def customer_lead_map
    restaurants = ZomatoRestaurant.assigned
    customer_list = restaurants.map(&:customer_id).uniq.compact
    lead_list = restaurants.map(&:customer_lead_id).uniq.compact

    customers = Customer.all.where('id NOT IN (?)', customer_list).where('lat IS NOT NULL').where('cust_type_id != 1')
    leads = CustomerLead.all.where('id NOT IN (?)', lead_list).where('latitude IS NOT NULL AND firstname != "" AND cust_type_id != 1').where('latitude IS NOT NULL')
    count = 0
    count_lead = 0
    customers.each do |customer|
      match = ZomatoRestaurant.where("(name LIKE \"%#{customer.firstname}%\" OR name Like \"%#{customer.lastname}%\") AND ABS(latitude - #{customer.lat}) < 0.0002 AND ABS(longitude - #{customer.lng}) < 0.0002").first
      next if match.nil?
      match.customer_id = customer.id
      match.save
      count += 1
    end

    leads.each do |lead|
      match = ZomatoRestaurant.where("(name LIKE \"%#{lead.firstname}%\" OR name LIKE \"%#{lead.lastname}%\") AND ABS(latitude - #{lead.latitude}) < 0.0002 AND ABS(longitude - #{lead.longitude}) < 0.0002").first
      next if match.nil?
      match.customer_lead_id = lead.id
      match.save
      count_lead += 1
    end
    puts count
    puts count_lead
  end

  def filter_viewed_spots
    customers_viewed = []
    restaurants = ZomatoRestaurant.all
    while !restaurants.blank?
      customers_viewed += Customer.near([restaurants.first.latitude, restaurants.first.longitude], 0.01, units: :km).map(&:id)
      restaurants -= ZomatoRestaurant.near([restaurants.first.latitude, restaurants.first.longitude], 0.01, units: :km)
    end
    customers_viewed.uniq
  end

  def search_by_zomato
    count_ping = 0
    query = 'https://developers.zomato.com/api/v2.1/search'

    # Selected Cuisines and useless Cuisines
    selected_cuisines = get_cuisines.map(&:to_s)
    inactive_cuisines = ZomatoCuisine.inactive_cuisines.map(&:name).sort.uniq

    customers = ZomatoRestaurant.all

    while !customers.blank?
      customer = customers.last

      # filter out near by restaurants
      near_by = ZomatoRestaurant.near([customer.latitude, customer.longitude], 0.2, units: :km).map(&:id)
      customers = customers.reject {|x| near_by.include?x.id}

      next if near_by.count > 40

      start = 0
      results_found = 100
      while (results_found > 40) && ((start * 20) < results_found) && start < 80
        response = HTTParty.get(query, query: {lat: customer.latitude, lon: customer.longitude, radius: 200, cuisines: selected_cuisines, start: start}, headers: {"user-key" => Rails.application.secrets.zomato_key })

        # if hit the daily limit, return the function
        return if response['results_found'].nil?

        restaurant_update_attribuets(response['restaurants'], inactive_cuisines)

        # search for next customer or search for next page
        results_found = response['results_found'].to_i
        start += 20
        count_ping += 1
        puts 'Counting ' + count_ping.to_s if count_ping % 100 == 0
        return if count_ping > 900
      end

    end

  end

  def search_by_geo
    # MultiGeocoder.geocode(location)
    count_ping = 0
    query = 'https://developers.zomato.com/api/v2.1/search'

    # Selected Cuisines and useless Cuisines
    selected_cuisines = get_cuisines.map(&:to_s)
    inactive_cuisines = ZomatoCuisine.inactive_cuisines.map(&:name).sort.uniq

    customers_viewed = []
    customers = Customer.where('lng IS NOT NULL AND cust_type_id != 1').select{ |x| x}

    # delete following block after data integrated
    # customers_viewed = filter_viewed_spots
    # customers = customers.select{ |x| !customers_viewed.include?x.id }
    # ------------------------------------------------------------------

    while !customers.blank?
      customer = customers.last

      existed_customer = ZomatoRestaurant.near([customer.lat, customer.lng], 0.5, units: :km).map(&:id)
      start = 0
      results_found = 100
      while (results_found > 40) && ((start * 20) < results_found) && start < 80 && existed_customer.count < 40
        response = HTTParty.get(query, query: {lat: customer.lat, lon: customer.lng, radius: 200, cuisines: selected_cuisines, start: start}, headers: {"user-key" => Rails.application.secrets.zomato_key })

        # if hit the daily limit, return the function
        return if response['results_found'].nil?

        restaurant_update_attribuets(response['restaurants'], inactive_cuisines)

        # search for next customer or search for next page
        results_found = response['results_found'].to_i
        start += 20
        count_ping += 1
        puts 'Counting ' + count_ping.to_s if count_ping % 100 == 0
        return if count_ping > 900
      end

      customers_viewed += Customer.near([customer.lat, customer.lng], 0.5, units: :km).map(&:id)
      customers = customers.select{ |x| !customers_viewed.include?x.id }
    end
  end # end def

  def restaurant_update_attribuets(restaurants, inactive_cuisines)
    return if restaurants.nil? || restaurants.blank?
    restaurants.each do |restaurantL3|
      restaurant = restaurantL3['restaurant']
      next if restaurant.nil?
      next if (inactive_cuisines + restaurant['cuisines'].split).sort.uniq == inactive_cuisines

      existed_restaurant = ZomatoRestaurant.filter_by_id(restaurant['id']).first

      if !existed_restaurant.nil? && existed_restaurant.aggregate_rating.nil?
        restaurant_attr = {thumb: restaurant['thumb'],\
          featured_image: restaurant['featured_image'],\
          aggregate_rating: restaurant['user_rating']['aggregate_rating'],\
          rating_text: restaurant['user_rating']['rating_text']
        }
        existed_restaurant.update_attributes(restaurant_attr)
        next
      elsif !existed_restaurant.nil?
        next
      end

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
          thumb: restaurant['thumb'],\
          featured_image: restaurant['featured_image'],\
          aggregate_rating: restaurant['user_rating']['aggregate_rating'],\
          rating_text: restaurant['user_rating']['rating_text'],\
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
