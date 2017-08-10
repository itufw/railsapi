class Status < ActiveRecord::Base
	has_many :orders

	def self.filter_by_id(status_id)
	  return find(status_id)
	end

	def self.can_update
		where(can_update: 1).order('statuses.order')
	end

	def self.sort
		order('statuses.order')
	end

	def self.problems
		where(send_reminder: 1).order('statuses.order')
	end
end
