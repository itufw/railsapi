class XeroAccountCode < ActiveRecord::Base

	def self.wet_payable
		return where(account_name: 'WET Payable').first
	end

	def self.shipping_revenue
		return where(account_name: 'Shipping Revenue').first
	end

	def self.wholesale
		return where(account_name: 'Wholesale').first
	end

	def self.retail
		return where(account_name: 'Retail').first
	end

end
