class CustStyle < ActiveRecord::Base
	has_many :customers

	# self.get_name(cust_style_id)
	# 	find(cust_style_id)

	def self.filter_by_id(cust_style_id)
		find(cust_style_id)
	end
end
