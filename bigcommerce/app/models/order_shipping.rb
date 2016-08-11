class OrderShipping < ActiveRecord::Base
	belongs_to :order
	belongs_to :address

	has_many :order_products
end
