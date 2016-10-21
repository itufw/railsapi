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
		xero_invoice = XeroInvoice.find_by_order_id(order_id)
		xero_invoice_id, invoice_number = xero_invoice.xero_invoice_id, xero_invoice.invoice_number unless xero_invoice.nil?
		Order.insert_invoice(order_id, xero_invoice_id, invoice_number)
	end

	def xero_sync
		# We have a new orders from BigC
		orders = Order.export_to_xero
		new_orders = [orders.last]

		new_orders.each do |o|

			order_id = o.id
			customer_id = o.customer_id
			# If its a new customer then create a new contact in Xero
			if Customer.is_new_customer_for_xero(customer_id)
				# TEST CREATING NEW INVOICE
				xero_contact = XeroContact.create_in_xero(Customer.filter_by_id(customer_id))
				Customer.insert_xero_contact_id(customer_id, xero_contact.contact_id)
			# Otherwise just get the xero contact id
			else
				xero_contact_id = Customer.get_xero_contact_id(customer_id)
				xero_contact = XeroContact.get_contact_from_xero(xero_contact_id)
			end
			return create_in_xero(o, xero_contact)
			# create a new invoice with line items
			#invoice_line_items(o)
			#invoice_saved = add_line_items(invoice_unsaved, order_id)
			#invoice = create_in_xero(o)
			#Order.insert_invoice(order_id, xero_invoice_id)
		end		
	end

	def invoice_line_items(order)
		order_id = order.id
		is_customer_wholesale = Customer.is_wholesale(order.customer)
		order_products = order.order_products
		order_total = order.total_inc_tax

		discount_rate = get_discount_rate(order)

		discounted_unit_price = Hash.new
		order_products.each { |op| discounted_unit_price[op.id] = (op.price_inc_tax * discount_rate) }

		discounted_ex_gst_unit_price = Hash.new
		discounted_unit_price.each {|op_id, d| discounted_ex_gst_unit_price[op_id] =  get_ex_gst_price(d)}

		inc_gst_shipping_price = order.shipping_cost_inc_tax
		ex_gst_shipping_price = get_ex_gst_price(inc_gst_shipping_price)

		if is_customer_wholesale
			wholesale_line_items(discount_rate, discounted_unit_price, discounted_ex_gst_unit_price,\
			inc_gst_shipping_price, ex_gst_shipping_price, order_id, order_products, order)
		else
			retail_line_items(discount_rate, discounted_unit_price, discounted_ex_gst_unit_price,\
			inc_gst_shipping_price, ex_gst_shipping_price, order_id, order_products)
		end

	end

	def retail_line_items(discount_rate, discounted_unit_price, discounted_ex_gst_unit_price,\
		inc_gst_shipping_price, ex_gst_shipping_price, invoice_number, order_products)
		
		order_products.each do |op|
			op_id = op.id
			product_id = op.product_id
			product_name = Product.product_name(product_id)
			XeroCalculation.insert_line_items_retail(invoice_number, product_id, product_name, op.qty,\
			op.price_inc_tax, discount_rate, discounted_unit_price[op_id],\
			discounted_ex_gst_unit_price[op_id])
		end

		XeroCalculation.insert_shipping_calculation(invoice_number, inc_gst_shipping_price,\
		ex_gst_shipping_price)
	end

	def wholesale_line_items(discount_rate, discounted_unit_price, discounted_ex_gst_unit_price,\
		inc_gst_shipping_price, ex_gst_shipping_price, invoice_number, order_products, order)

		order_total = order.total_inc_tax

		discounted_ex_taxes_unit_price = Hash.new
		discounted_ex_gst_unit_price.each {|op_id, d| discounted_ex_taxes_unit_price[op_id] = get_ex_taxes_price(d)}

		wet_unadjusted_order_product_price = Hash.new
		discounted_ex_taxes_unit_price.each {|op_id, d| wet_unadjusted_order_product_price[op_id] = wet_unadjusted_order_product(d, op_id)}
	
		wet_unadjusted_total = wet_unadjusted_order_product_price.values.sum

		ship_deduction = calculate_ship_deduction(order.qty)

		subtotal_ex_gst = (get_ex_gst_price(order_total) - ex_gst_shipping_price - ship_deduction)

		wet_adjusted = (subtotal_ex_gst - get_ex_taxes_price(subtotal_ex_gst))

		adjustment = (wet_unadjusted_total - wet_adjusted)

		line_amounts_total_ex_taxes = 0
		discounted_ex_taxes_unit_price.each {|op_id, d| line_amounts_total_ex_taxes += d.round(2) * OrderProduct.total_qty(op_id) }

		total_ex_gst = line_amounts_total_ex_taxes.round(2) + wet_adjusted.round(2) + adjustment.round(2) + ex_gst_shipping_price.round(2)

		gst = get_inc_gst_price(total_ex_gst)
		
		rounding_error = order.total_inc_tax - total_ex_gst - gst

		order_products.each do |op|
			op_id = op.id
			product_id = op.product_id
			product_name = Product.product_name(product_id)

			XeroCalculation.insert_line_items_ws(invoice_number, product_id, product_name,\
	 		op.qty, op.price_inc_tax, discount_rate, discounted_unit_price[op_id],\
	 		discounted_ex_gst_unit_price[op_id], discounted_ex_taxes_unit_price[op_id],\
	 		wet_unadjusted_order_product_price[op_id])
		end

		XeroCalculation.insert_wet_calculation(invoice_number, wet_unadjusted_total, ship_deduction,\
		subtotal_ex_gst, wet_adjusted)

		XeroCalculation.insert_adjustment(invoice_number, adjustment)

		XeroCalculation.insert_shipping_calculation(invoice_number, inc_gst_shipping_price,\
		ex_gst_shipping_price)

		XeroCalculation.insert_rounding(invoice_number, line_amounts_total_ex_taxes,\
	 	ex_gst_shipping_price, total_ex_gst, gst, order_total, rounding_error)
	end

	def get_discount_rate(order)
		order_total_ex_shipping = order.total_inc_tax - order.shipping_cost_inc_tax
		order_product_total = OrderProduct.order_sum(order.order_products)
		return order_total_ex_shipping/order_product_total
	end

	def get_ex_gst_price(inc_gst_price)
		return inc_gst_price/(1 + (TaxPercentage.gst_percentage/100))
	end

	def get_inc_gst_price(ex_gst_price)
		return ex_gst_price * (TaxPercentage.gst_percentage/100)
	end

	# But only if customer type is Retail
	def get_ex_taxes_price(ex_gst_price)
		return ex_gst_price/(1 + (TaxPercentage.wet_percentage/100))
	end

	def wet_unadjusted_order_product(ex_taxes_unit_price, order_product_id)
		qty = OrderProduct.total_qty(order_product_id)
		return ((qty * ex_taxes_unit_price) * (TaxPercentage.wet_percentage/100))
	end

	def calculate_ship_deduction(qty)
		ship_charge = TaxPercentage.ship_charge_percentage/100
		ex_gst_ship_charge = get_ex_gst_price(ship_charge)
		return qty * ex_gst_ship_charge
	end


	def create_in_xero(order, contact)
  		xero = XeroConnection.new.connect

  		invoice_number = order.id

  		invoice = xero.Invoice.build(invoice_number: invoice_number.to_s, contact: contact,\
  			type: "ACCREC", date: order.date_created.to_date,\
  			due_date: 30.days.since(order.date_created.to_date), sent_to_contact: false)

  		line_items = XeroCalculation.get_line_items(invoice_number)

		line_items.each do |l|

			unit_amount_clean = l.discounted_ex_taxes_unit_price.to_s.to_f.round(2)

			invoice.add_line_item(item_code: l.item_code.to_s,\
			description: l.description.to_s, quantity: l.qty,\
			unit_amount: unit_amount_clean,\
			tax_type: l.tax_type.to_s, account_code: l.account_code.to_s)
		end

		invoice.save
  	end


	# def add_line_items(invoice_unsaved, invoice_number)
	# 	line_items = XeroCalculation.get_line_items(invoice_number)
	# 	line_items.each do |l|

	# 		unit_amount_clean = l.discounted_ex_taxes_unit_price.to_s.to_f.round(2)
	# 		invoice_unsaved.add_line_item(item_code: l.item_code.to_s,\
	# 		description: l.description.to_s, quantity: l.qty,\
	# 		unit_amount: unit_amount_clean,\
	# 		tax_type: l.tax_type.to_s, account_code: l.account_code.to_s)
	# 	end

	# 	#invoice = invoice_unsaved.save
	# 	return invoice_unsaved
	# end

end