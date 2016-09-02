class XeroOverPayment < ActiveRecord::Base
	self.primary_key = 'xero_over_payment_id'

	has_many :xero_over_payment_allocation

end
