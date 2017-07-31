class ZomatoCuisine < ActiveRecord::Base
  def self.active_cuisines
    where(active: 1)
  end
  def self.inactive_cuisines
    where(active: 0)
  end
  def self.filter_priority(priority)
    where(priority_group: priority)
  end
end
