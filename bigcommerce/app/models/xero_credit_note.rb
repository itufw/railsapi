class XeroCreditNote < ActiveRecord::Base
	self.primary_key = 'xero_credit_note_id'

	has_many :xero_credit_note_allocations
	belongs_to :xero_contact
end
