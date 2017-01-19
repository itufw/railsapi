class Address < ActiveRecord::Base
	belongs_to :customer

	has_many :order_shippings
	has_many :orders, through: :order_shippings

	has_many :billing_orders, class_name: :Order, foreign_key: :billing_address_id

	def insert_or_update(a, customer_id, order_id)
		if address_not_exist(order_id)
			time = Time.now.to_s(:db)
			address = "('#{order_id}','#{customer_id}',\"#{a[:first_name]}\",\"#{a[:last_name]}\",\"#{a[:company]}\",\
			\"#{a[:street_1]}\",\"#{a[:street_2]}\",\"#{a[:city]}\",'#{a[:state]}','#{a[:zip]}',\
			\"#{a[:country]}\",'#{a[:phone]}',\"#{a[:email]}\",'#{time}', '#{time}')"

			sql = "INSERT INTO addresses (id, customer_id, firstname, lastname, company,\
			street_1, street_2, city, state, postcode,\
			country, phone, email, created_at, updated_at)\
			VALUES #{address}"

			ActiveRecord::Base.connection.execute(sql)
		end
	end

	def address_not_exist(order_id)
		if Address.where(id: order_id).count == 0
			return true
		end
		return false
	end
end
