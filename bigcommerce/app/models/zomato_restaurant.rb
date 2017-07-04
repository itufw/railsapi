class ZomatoRestaurant < ActiveRecord::Base

  scoped_search on: [:name, :address, :locality, :average_cost_for_two, :cuisines]

  self.per_page = 15

  def self.filter_by_id(id)
    where(id: id)
  end
end
