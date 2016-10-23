require 'bigcommerce_connection.rb'

class Status < ActiveRecord::Base
	has_many :orders

	def scrape

		status_api = Bigcommerce::OrderStatus
		inserts = []

		status_api.all.each do |s|

			time = Time.now.to_s(:db)

			inserts.push "('#{s.id}', '#{s.name}', '#{time}', '#{time}')"
		end

		sql = "INSERT INTO statuses (id, name, created_at, updated_at) VALUES #{inserts.join(", ")}"

		ActiveRecord::Base.connection.execute('SET SQL_MODE="NO_AUTO_VALUE_ON_ZERO";')
		ActiveRecord::Base.connection.execute(sql)		

	end

	def self.filter_by_id(status_id)
	  return find(status_id)
	end


end
