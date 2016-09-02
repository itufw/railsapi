class XeroReceipt < ActiveRecord::Base
	self.primary_key = 'xero_receipt_id'

	belongs_to :xero_contact
end
