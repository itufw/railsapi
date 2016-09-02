class XeroContact < ActiveRecord::Base
	self.primary_key = 'xero_contact_id'

	has_many :xero_credit_notes
	has_many :xero_invoices
	has_many :xero_receipts
end
