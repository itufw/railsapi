module RakeTaskHelper

	def can_start_update
		return ((!Revision.end_time.nil?) || (Revision.attempt_count < 2))
	end

	def can_start_xero_sync
		return !XeroRevision.end_time.nil?
	end
end
