class TaxCode < ActiveRecord::Base

	def self.gst_tax_code
		return where(customer_type: 'Retail').tax_code.to_s
	end

	def self.shipping_tax_code
		return where(customer_type: 'Shipping').tax_code.to_s
	end


end
