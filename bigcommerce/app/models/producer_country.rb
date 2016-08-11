class ProducerCountry < ActiveRecord::Base
	has_many :producers
	has_many :producer_regions

	has_many :products
end
