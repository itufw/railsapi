module XeroControllerHelper

	def link_skype_id(customer_id)
		xero_contact = XeroContact.find_by_skype_id(customer_id)
		contact_id = xero_contact.xero_contact_id unless xero_contact.nil?
		Customer.insert_xero_contact_id(customer_id, contact_id)
	end

	def link_invoice_id(order_id)
		xero_invoice = XeroInvoice.find_by_order_id(order_id)
		xero_invoice_id, invoice_number = xero_invoice.xero_invoice_id, xero_invoice.invoice_number unless xero_invoice.nil?
		Order.insert_invoice(order_id, xero_invoice_id, invoice_number)
	end

	def xero_sync
		# We have a new orders from BigC
		new_orders = Order.xero_invoice_id_is_null
		new_orders.each do |o|
			is_new_customer = Customer.new_customer_for_xero(o.customer_id)
			# If its a new customer then create a new contact in Xero
			if is_new_customer
				xero_contact_id = ?
				Customer.insert_xero_contact_id(o.customer_id, xero_contact_id)
			else
				xero_contact_id = Customer.get_xero_contact_id(o.customer_id)
			end
			# create a new invoice with line items
			xero_invoice_id = 
			Order.insert_invoice(o.id, xero_invoice_id, o.id)
			
	end

	def calculations_for_xero_invoice(order_id)
		

	end

	def get_discount_rate(order_id)
		order_total = Order.find(order_id).total_inc_tax
		order_product_total = OrderProduct.order_sum(order_id)
		if order_total === order_product_total
			return order_total.to_f/order_product_total
		else
			return 1
		end
	end
end