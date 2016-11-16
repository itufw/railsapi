class Revision < ActiveRecord::Base

	def self.updated(start_time)
		only_row = first
		only_row.last_update_time = start_time.utc
		only_row.save
	end
end
