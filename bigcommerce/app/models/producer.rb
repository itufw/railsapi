class Producer < ActiveRecord::Base
	has_many :products

	belongs_to :producer_country
end
