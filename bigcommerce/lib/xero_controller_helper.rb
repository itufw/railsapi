module XeroControllerHelper

	def link_skype_id(customer_id)
		contact_id = XeroContact.find_by_skype_id(customer_id).xero_contact_id
		return contact_id
	end
end