require 'bigcommerce_connection.rb'
require 'csv'

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

	def csv_import

		CSV.foreach("db/csv/order_status.csv", headers: true) do |row|

			row_hash = row.to_hash
			Status.update(row_hash['Id'], alt_name: row_hash['Alternate Name'], order: row_hash['Order'],\
			 	in_use: row_hash['In Use'], confirmed: row_hash['Confirmed'], in_transit: row_hash['InTransit'],\
			 	delivered: row_hash['Delivered'], picking: row_hash['Picking'], valid_order: row_hash['ValidOrder'])
		end
	end


	def self.filter_by_id(status_id)
	  return find(status_id)
	end


end
