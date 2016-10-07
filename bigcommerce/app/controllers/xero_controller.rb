class XeroController < ApplicationController

	def link_bigc_xero_contact
		Customer.all.each {|c| Customer.insert_xero_contact_id(c.id, link_skype_id(c.id))}
	end

end