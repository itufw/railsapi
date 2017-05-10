require 'bigcommerce_connection.rb'
require 'geokit'

class Address < ActiveRecord::Base
	include Geokit::Geocoders

	belongs_to :customer

	has_many :order_shippings
	has_many :orders, through: :order_shippings

	has_many :billing_orders, class_name: :Order, foreign_key: :billing_address_id

	def insert_or_update(a, customer_id, order_id)
		if address_not_exist(order_id)
			time = Time.now.to_s(:db)

			lat, lng = get_lat_lng(a[:street_1], a[:street_2], a[:city], a[:state], a[:country])
			address = Address.new
			address.id, address.customer_id, address.firstname, address.lastname = order_id, customer_id, a[:first_name], a[:last_name]
			address.company = a[:company]
			address.street_1, address.street_2, address.city, address.state, address.postcode = a[:street_1], a[:street_2], a[:city], a[:state], a[:zip]
			address.country = a[:country]
			address.phone, address.email = a[:phone], a[:email]
			address.created_at, address.updated_at = time, time
			address.lat, address.lng = lat, lng if lat.is_a? Numeric
			address.save
		end
	end

	def update_from_api(update_time)
		address_api = Bigcommerce::Order

		order_count = address_api.count(min_date_modified: update_time).count
		limit = 50
		order_pages = (order_count / limit) + 1
		page_number = 1

		order_pages.times do
				orders = address_api.all(min_date_modified: update_time, page: page_number)
				return if orders.blank?

				orders.each do |o|
					if customer_not_exist(o.customer_id)
						Address.new.insert_or_update(o.billing_address,o.customer_id,o.id)
					end
				end
				page_number += 1
		end

	end

	def customer_not_exist(customer_id)
		if Address.where(customer_id: customer_id).count == 0
			return true
		end
		return false
	end

	def address_not_exist(order_id)
		if Address.where(id: order_id).count == 0
			return true
		end
		return false
	end

	def get_lat_lng(street_1, street_2, city, state, country)
		location = ""
		location += street_1 + " "
		location += street_2 + " " unless street_2.nil?
		location += ", " + city + ", " + state + ", " + country
		coords = MultiGeocoder.geocode(location)
		[coords.lat,coords.lng]
	end

	def update_gps_all
		addresses = Address.where("lat IS NULL AND company <> 'UFW'")
		addresses.each do |address|
			location = ""
			location += address.street_1 + " "
			location += address.street_2 + " " unless address.street_2.nil?
			location += ", " + address.city + ", " + address.state + ", " + address.country
			coords = MultiGeocoder.geocode(location)
			address.lat = coords.lat
			address.lng = coords.lng

			address.save
		end
	end

	def self.has_lat_lng
		where("addresses.lat IS NOT NULL AND addresses.lng IS NOT NULL")
		end

	def self.group_by_customer
		group("addresses.customer_id")
		end
end
