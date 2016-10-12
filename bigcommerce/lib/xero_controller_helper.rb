module XeroControllerHelper

	def link_skype_id(customer_id)
		xero_contact = XeroContact.find_by_skype_id(customer_id)
		contact_id = xero_contact.xero_contact_id unless xero_contact.nil?
		return contact_id
	end
end