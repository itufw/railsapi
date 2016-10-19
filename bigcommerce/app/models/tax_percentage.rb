class TaxPercentage < ActiveRecord::Base

	def self.gst_percentage
		return where(tax_name: 'GST').first.tax_percentage
	end
end
