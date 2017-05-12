class CustGroup < ActiveRecord::Base

	has_many :customers
	has_many :customer_leads

end
