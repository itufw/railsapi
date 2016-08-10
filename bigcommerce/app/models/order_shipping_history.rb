class OrderShippingHistory < ActiveRecord::Base
	belongs_to :order_history
	belongs_to :address

	has_many :order_product_histories
end
