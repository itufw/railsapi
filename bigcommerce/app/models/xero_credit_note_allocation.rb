class XeroCreditNoteAllocation < ActiveRecord::Base
	self.primary_key = 'xero_credit_note_allocation_id'

	belongs_to :xero_invoice
	belongs_to :xero_credit_note

	def scrape(allocations, credit_note_id)

		allocations.each do |a|

			time = Time.now.to_s(:db)

			sql = "INSERT INTO xero_credit_note_allocations (xero_credit_note_allocation_id,\
			xero_credit_note_id, xero_invoice_id, xero_invoice_number, applied_amount,\
			created_at, updated_at) VALUES ('#{SecureRandom.uuid}', '#{credit_note_id}', '#{a.invoice.invoice_id}',\
			'#{a.invoice.invoice_number}', '#{a.applied_amount}', '#{time}', '#{time}')"

			ActiveRecord::Base.connection.execute(sql)

		end



	end
end
