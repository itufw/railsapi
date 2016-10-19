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
			# Otherwise just get the xero contact id
			else
				xero_contact_id = Customer.get_xero_contact_id(o.customer_id)
			end
			# create a new invoice with line items
			xero_invoice_id = create_invoice(o)
			Order.insert_invoice(o.id, xero_invoice_id, o.id)
		end		
	end

	def create_invoice(order)
		# We want the order total in Bigc to be the order total in Xero
		# All other values are different so we have to start from the ground up

		# Calculate original order total by summing totals of order products
		# see if a discount was applied, if yes get the rate, otherwise return 1
		discount_rate = get_discount_rate(order)

		# Unit amounts for xero line items include tax
		# Get total for each order product by qty * price per bottle
		# Then apply discount, then divide by qty to get the unit amount
		line_items_unit_amount_h = Hash.new
		order.order_products.each { |op| line_items_unit_amount_h[op.id] = discounted_unit_amount(op.price_inc_tax, op.qty, discount_rate) }

		# multiply unit amount by quantity to get line amount total
		line_items_totals_h = Hash.new
		order.order_products.each { |op| line_items_totals_h[op.id] = discounted_line_item_total(discounted_unit_amount(op.price_inc_tax, op.qty, discount_rate), op.qty) }
		
		# line amount totals / 1 + GST/100 gives tax amount
		line_items_tax_h = Hash.new
		line_items_totals_h.each { |order_product_id, total| line_items_tax_h[order_product_id] = gst_price(total) }

		# sum tax values first, then get sub total
		invoice_total_tax = line_items_tax_h.values.sum
		invoice_sub_total = calculate_subtotal(order.total_inc_tax, invoice_total_tax)
		#invoice = XeroInvoice.create_in_xero(contact, o, invoice_sub_total, invoice_total_tax)

		#invoice_with_line_items = XeroInvoiceLineItem.add_line_items(invoice, order.order_products, line_items_unit_amount_h, line_items_totals_h, line_items_tax_h)

		# add shipping as a line item
		# invoice_with_line_items.add_line_item(item_code: 'SHIPPING',\
		#  description: 'Shipping Costs - Shipping - Fastway', quantity: 1, unit_amount: order.shipping_cost_inc_tax,\
		#  account_code: TaxCode.shipping_tax_code, tax_type: 'OUTPUT', tax_amount: gst_price(order.shipping_cost_inc_tax),\
		#  line_amount: order.shipping_cost_inc_tax)

		# invoice_with_line_items.save
		# return invoice_with_line_items.invoice_id
	end

	def get_discount_rate(order)
		order_total = order.total_inc_tax
		order_product_total = OrderProduct.order_sum(order.order_products)
		if order_total === order_product_total
			return 1
		else
		 	return order_total.to_f/order_product_total
		end
		return order_product_total
	end

		# Inc Tax 
		# Also Invoice Line Item's Unit Amount
	def discounted_unit_amount(op_price_inc_tax, op_qty, discount_rate)
		total = op_price_inc_tax * op_qty * discount_rate
		return (total.to_f/op_qty).round(2)
	end

	def discounted_line_item_total(op_discounted_total_per_qty, qty)
		return (op_discounted_total_per_qty * qty).round(2)
	end

	def gst_price(inc_gst_price)
		return (inc_gst_price/(1 + TaxPercentage.gst_percentage)).round(2)
	end

	def calculate_subtotal(total, total_tax)
		return total - total_tax
	end

end