class OrderProductHistory < ActiveRecord::Base
	belongs_to :order_history
	belongs_to :product

	belongs_to :order_shipping_history

end
