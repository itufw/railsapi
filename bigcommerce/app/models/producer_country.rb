class ProducerCountry < ActiveRecord::Base
  has_many :producers
  has_many :producer_regions
  has_many :products

  def self.filter_by_id(producer_country_id)
    find(producer_country_id)
  end

  def self.producer_country_filter(producer_country_ids)
    return where(id: producer_country_ids) if producer_country_ids
    all
  end

  def self.product_country
    where('short_name NOT IN (?)', ['UFW', 'na'])
  end

end
