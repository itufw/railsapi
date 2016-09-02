class XeroCreditNoteAllocation < ActiveRecord::Base
	self.primary_key = 'xero_credit_note_allocation_id'

	belongs_to :xero_invoice
	belongs_to :xero_credit_note
end
