module RakeTaskHelper

	def can_start_update
		return ((!Revision.bigcommerce.end_time.nil?) || (Revision.bigcommerce.attempt_count < 2))
	end

	def can_start_xero_sync
		return !Revision.xero.end_time.nil?
	end
end
