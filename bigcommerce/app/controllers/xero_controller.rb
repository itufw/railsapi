require 'xero_controller_helper.rb'
class XeroController < ApplicationController

	include XeroControllerHelper
	
	def link_bigc_xero_contact
		Customer.xero_contact_id_is_null.each {|c| link_skype_id(c.id)}
	end

	def link_bigc_xero_orders
		Order.xero_invoice_id_is_null.each {|o| link_invoice_id(o.id)}
	end

	

end