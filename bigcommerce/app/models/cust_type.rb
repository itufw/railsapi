class CustType < ActiveRecord::Base
	has_many :customers
	has_many :customer_leads

	# def self.get_name(cust_type_id)
	# 	return find(cust_type_id).name
	# end
end
