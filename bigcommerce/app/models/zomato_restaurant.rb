class ZomatoRestaurant < ActiveRecord::Base

  belongs_to :customer
  belongs_to :customer_lead

  geocoded_by :address
  reverse_geocoded_by :latitude, :longitude

  scoped_search on: [:name, :address, :locality, :average_cost_for_two, :cuisines]

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
end
