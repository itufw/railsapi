class TaxPercentage < ActiveRecord::Base

	def self.gst_percentage
		return where(tax_name: 'GST').first.tax_percentage
	end

	def self.wet_percentage
		return where(tax_name: 'WET').first.tax_percentage
	end

	# get shipping rate inside Victoria for a bottle of beer
	def self.get_siv
		return where(id: 5).first.tax_percentage
	end

	# get shipping rate outside Victoria for a bottle of beer
	# such as Queensland and NSW
	def self.get_sov
		return where(id: 6).first.tax_percentage
	end

	def self.ship_charge_percentage
		return where(tax_name: 'Shipcharge').first.tax_percentage
	end

	def self.handling_fee
		return where(tax_name: 'Handling').first.tax_percentage
	end
end
