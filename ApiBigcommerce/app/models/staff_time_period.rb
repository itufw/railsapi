require 'csv'

class StaffTimePeriod < ActiveRecord::Base

	belongs_to :staff

	def update_month

	end

	def update_using_default_start_date

	end

	def update_quarter

	end

	def csv_import

		CSV.foreach("db/csv/staff_time_periods.csv", headers: true) do |row|
			StaffTimePeriod.create(row.to_hash)
		end
	end
end
