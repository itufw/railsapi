class ProductSubType < ActiveRecord::Base
	belongs_to :product_type
	has_many :products
end
