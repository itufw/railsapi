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
			# If its a new customer then create a new contact in Xero
			if Customer.is_new_customer_for_xero(o.customer_id)
				# TEST CREATING NEW INVOICE
				xero_contact_id = XeroContact.create_in_xero(Customer.filter_by_id(o.customer_id))
				Customer.insert_xero_contact_id(o.customer_id, xero_contact_id)
			else
				xero_contact_id = Customer.get_xero_contact_id(o.customer_id)
			end
			# create a new invoice with line items
			
			# Order.insert_invoice(o.id, xero_invoice_id, o.id)
		end
			
	end

	def invoice_calculations(order)
		discount_rate = get_discount_rate(order.id)

		line_items_unit_amount_h = Hash.new
		line_items_unit_amount_h = order.order_products.each { |op| line_items_unit_amount_h[op.id] = discounted_unit_amount(op.price_inc_tax, discount_rate) }

		line_items_totals_h = Hash.new
		line_items_totals_h = order.order_products.each { |op| line_items_totals_h[op.id] = discounted_line_item_total(discounted_unit_amount(op.price_inc_tax, discount_rate), op.qty) }
		
		line_items_tax_h = Hash.new
		line_items_tax_h = line_items_totals_h.each { |order_product_id, total| line_items_tax_h[order_product_id] = gst_price(total) }

		invoice_total_tax = line_items_tax_a.sum
		invoice_sub_total = calculate_subtotal(order.total_inc_tax, invoice_total_tax)
		invoice = create_in_xero(contact, o, invoice_sub_total, invoice_total_tax)

		invoice_with_line_items = add_line_items(invoice, order.order_products, line_items_unit_amount_h, line_items_totals_h, line_items_tax_h)

		invoice_with_line_items.add_line_item(item_code: 'SHIPPING',\
		 description: 'Shipping Costs - Shipping - Fastway', quantity: 1, unit_amount: order.shipping_cost_inc_tax,\
		 account_code: TaxCode.shipping_tax_code, tax_type: 'OUTPUT', tax_amount: gst_price(order.shipping_cost_inc_tax),\
		 line_amount: order.shipping_cost_inc_tax)

		invoice_with_line_items.save
		return invoice_with_line_items.invoice_id
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

		# Inc Tax 
		# Also Invoice Line Item's Unit Amount
	def discounted_unit_amount(op, discount_rate)
		total = OrderProduct.order_product_total(op, discount_rate)
		return (total.to_f/op.qty).round(2)
	end

	def discounted_line_item_total(op_discounted_total_per_qty, qty)
		return order_product_discounted_total * qty
	end

	def gst_price(inc_gst_price)
		return inc_gst_price/(1 + TaxPercentage.gst_percentage)
	end

	def calculate_subtotal(total, total_tax)
		return total - total_tax
	end

end