require 'bigcommerce_connection.rb'
require 'clean_data.rb'

class Coupon < ActiveRecord::Base
	
	has_many :orders

end
