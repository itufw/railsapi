require 'csv'

class CustStyle < ActiveRecord::Base
	has_many :customers

	def csv_import

		CSV.foreach("db/csv/cust_style.csv", headers: true) do |row|

			row_hash = row.to_hash

			CustStyle.create(id: row_hash['Id'], name: row_hash['CustStyleName'])
		end
	end
end
