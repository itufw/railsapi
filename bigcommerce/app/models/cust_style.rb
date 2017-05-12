class CustStyle < ActiveRecord::Base
	has_many :customers
	has_many :customer_leads

	# self.get_name(cust_style_id)
	# 	find(cust_style_id)

	def self.filter_by_id(cust_style_id)
		find(cust_style_id)
	end
end
