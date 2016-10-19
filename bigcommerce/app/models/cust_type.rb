require 'csv'

class CustType < ActiveRecord::Base
	has_many :customers


	def csv_import

		CSV.foreach("db/csv/cust_type.csv", headers: true) do |row|

			row_hash = row.to_hash

			CustType.create(id: row_hash['Id'], name: row_hash['CustTypeName'])
		end
	end

end
