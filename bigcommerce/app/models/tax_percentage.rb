class TaxPercentage < ActiveRecord::Base

	def self.gst_percentage
		return where(tax_name: 'GST').first.tax_percentage
	end

	def self.wet_percentage
		return where(tax_name: 'WET').first.tax_percentage
	end

	def self.ship_charge_percentage
		return where(tax_name: 'Shipcharge').first.tax_percentage
	end
end
