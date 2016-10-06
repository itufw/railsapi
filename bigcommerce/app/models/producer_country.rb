class ProducerCountry < ActiveRecord::Base
  has_many :producers
  has_many :producer_regions
  has_many :products

  def self.filter_by_id(producer_country_id)
    find(producer_country_id)
  end
  
end
