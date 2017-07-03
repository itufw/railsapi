class ZomatoRestaurant < ActiveRecord::Base

  def self.filter_by_id(id)
    where(id: id)
  end
end
