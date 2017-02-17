class Revision < ActiveRecord::Base

	def self.end_update(start_time, end_time)
		only_row = first
		only_row.start_time = start_time.utc
		only_row.end_time = end_time.utc
		only_row.attempt_count = 0
		only_row.save
	end

	def self.start_update
		only_row = first
		only_row.end_time = nil
		only_row.attempt_count = (only_row.attempt_count.nil?) ? 1 : (only_row.attempt_count + 1)
		only_row.save
	end

	def self.update_time_iso
		first.start_time.iso8601
	end

	def self.update_time
		first.start_time
	end

	def self.end_time
		first.end_time
	end

	def self.attempt_count
		first.attempt_count
	end

	def self.update_end_time
		only_row = first
		only_row.end_time = only_row.start_time
		only_row.save
	end
end
