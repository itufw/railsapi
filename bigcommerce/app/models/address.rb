class Address < ActiveRecord::Base
	belongs_to :customer

	has_many :order_shippings
	has_many :orders, through: :order_shippings

	has_many :billing_orders, class_name: :Order, foreign_key: :billing_address_id

end
