require 'xero_connection.rb'

module XeroControllerHelper

	def link_skype_id(customer_id)
		xero_contact = XeroContact.find_by_skype_id(customer_id)
		contact_id = xero_contact.xero_contact_id unless xero_contact.nil?
		Customer.insert_xero_contact_id(customer_id, contact_id)
	end

	# Similar Contacts in Xero have been merged to one, but they are different in Xero
	# Hence for customers that don't have a xero_contact_id, we find customers with
	# same name and give them its xero_contact_id
	def link_skype_id_by_customer_name(customer_id, actual_name)
		xero_contact_id = Customer.xero_contact_id_of_duplicate_customer(actual_name)
		Customer.insert_xero_contact_id(customer_id, xero_contact_id)
	end

	def link_invoice_id(order_id)
		xero_invoice_id = XeroInvoice.find_by_order_id(order_id)
		Order.insert_invoice(order_id, xero_invoice_id) unless xero_invoice_id.nil?
	end


end