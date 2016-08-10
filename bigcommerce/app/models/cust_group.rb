require 'csv'
require 'clean_data.rb'

class CustGroup < ActiveRecord::Base
	
	has_many :customers

	def csv_import

		CSV.foreach("db/csv/cust_group.csv", headers: true) do |row|

			row_hash = row.to_hash

			group_name = CleanData.new.remove_apostrophe(row_hash['GroupName'])
			CustGroup.create(id: row_hash['id'], name: group_name)

		end

	end

end
