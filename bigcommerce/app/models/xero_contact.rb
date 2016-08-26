require 'uuid_helper.rb'



class XeroContact < ActiveRecord::Base
	include UUIDHelper
	
	self.primary_key = 'contact_id'

	has_many :xero_invoices, foreign_key: :contact_id
end
