class ZomatoRestaurant < ActiveRecord::Base

  belongs_to :customer
  belongs_to :customer_lead

  geocoded_by :address
  reverse_geocoded_by :latitude, :longitude

  scoped_search on: [:name, :locality, :average_cost_for_two]

  self.per_page = 15

  def self.filter_by_id(id)
    where(id: id)
  end

# Order by attributes
  def self.order_by_name(direction)
    order('name ' + direction)
  end

  def self.order_by_cost(direction)
    order('average_cost_for_two ' + direction)
  end

  def self.order_by_cuisine(direction)
    order('cuisines ' + direction)
  end

  def self.order_by_locality(direction)
    order('locality ' + direction)
  end

  def self.unassigned
    where(customer_id: nil, customer_lead_id: nil)
  end

  def self.assigned
    where('customer_id IS NOT NULL OR customer_lead_id IS NOT NULL')
  end

  def self.cuisine_search(cuisine)
    return where("cuisines Like '%#{cuisine.strip}%'") if cuisine.is_a? String
    if ((cuisine.is_a?Array) && (!cuisine.blank?))
      query = cuisine.join("%' OR cuisines LIKE '%")
      query += "%'"
      query = "cuisines LIKE '%" + query
      return where(query)
    end
    all
  end
end
