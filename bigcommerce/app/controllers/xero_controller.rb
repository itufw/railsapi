require 'xero_controller_helper.rb'
class XeroController < ApplicationController

	include XeroControllerHelper
	
	def link_bigc_xero_contact
		Customer.xero_contact_id_is_null.each {|c| Customer.insert_xero_contact_id(c.id, link_skype_id(c.id))}
	end

end