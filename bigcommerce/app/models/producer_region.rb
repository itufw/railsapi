class ProducerRegion < ActiveRecord::Base
	belongs_to :producer_country

	has_many :products

	def self.country_filter(country_id)
		return where(producer_country_id: country_id) if country_id
		return all
	end
end
