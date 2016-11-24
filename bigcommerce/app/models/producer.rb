class Producer < ActiveRecord::Base
	has_many :products

	belongs_to :producer_country

	def self.country_filter(country_id)
		return where(producer_country_id: country_id) if country_id
		return all
	end
end
