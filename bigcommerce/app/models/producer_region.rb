class ProducerRegion < ActiveRecord::Base
	belongs_to :producer_country

	has_many :products
end
