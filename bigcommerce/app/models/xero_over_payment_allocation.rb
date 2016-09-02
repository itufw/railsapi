class XeroOverPaymentAllocation < ActiveRecord::Base
	self.primary_key = 'xero_over_payment_allocation_id'

	belongs_to :xero_invoice
	belongs_to :xero_over_payment

	# SecureRandom.uuid
end
