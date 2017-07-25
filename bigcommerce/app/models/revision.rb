class Revision < ActiveRecord::Base

	def end_update(start_time, end_time)
		only_row = self
		only_row.start_time = start_time.utc
		only_row.end_time = end_time.utc
		only_row.attempt_count = 0
		only_row.save
	end

	def start_update
		only_row = self
		only_row.end_time = nil
		only_row.attempt_count = (only_row.attempt_count.nil?) ? 1 : (only_row.attempt_count + 1)
		only_row.save
	end

	def update_time_iso
		self.start_time.iso8601
	end

	def update_time
		self.start_time
	end

	def update_end_time
		only_row = self
		only_row.end_time = only_row.start_time
		only_row.save
	end

	def self.bigcommerce
		find(1)
	end

	def self.xero
		find(2)
	end

	def self.google
		find(3)
	end

	def self.fastway
		find(4)
	end
end
