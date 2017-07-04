module XeroInvoiceCalculations
    def xero_sync
        # We have a new orders from BigC
        new_orders = Order.export_to_xero
        new_orders.each do |o|
            order_id = o.id

            next if XeroInvoice.is_submitted(order_id)
            customer_id = o.customer_id
            # If its a new customer then create a new contact in Xero
            if Customer.is_new_customer_for_xero(o.customer)
                xero_contact = XeroContact.create_in_xero(o.customer)
                xero_contact_id = xero_contact.contact_id

                # insert the new contact created in Xero into our database.
                XeroContact.new.insert_or_update_contact(xero_contact)
                Customer.insert_xero_contact_id(customer_id, xero_contact_id)
            # Otherwise just get the xero contact id
            else
                xero_contact_id = Customer.get_xero_contact_id(o.customer)
                next if xero_contact_id.nil?
                # xero_contact = XeroContact.get_contact_from_xero(xero_contact_id)
            end
            invoice_line_items(o) unless XeroCalculation.get_line_items(order_id).count > 0
            create_in_xero(o, xero_contact_id)
        end
    end

    def invoice_line_items(order)
        order_id = order.id
        is_customer_wholesale = Customer.is_wholesale(order.customer)
        order_products = order.order_products
        order_total = order.total_inc_tax

        gst_percentage = TaxPercentage.gst_percentage

        discount_rate = get_discount_rate(order)

        product_names = {}
        order_products.each { |op| product_names[op.id] = op.product.name }

        product_qtys = {}
        order_products.each { |op| product_qtys[op.id] = op.qty }

        discounted_unit_price = {}
        order_products.each { |op| discounted_unit_price[op.id] = (op.price_inc_tax * discount_rate) }

        discounted_ex_gst_unit_price = {}
        discounted_unit_price.each { |op_id, d| discounted_ex_gst_unit_price[op_id] = get_ex_gst_price(d, gst_percentage) }

        inc_gst_shipping_price = order.shipping_cost_inc_tax
        ex_gst_shipping_price = get_ex_gst_price(inc_gst_shipping_price, gst_percentage)

        if is_customer_wholesale
            wholesale_line_items(discount_rate, discounted_unit_price, discounted_ex_gst_unit_price,\
                                 inc_gst_shipping_price, ex_gst_shipping_price, order_id, order_products, order,\
                                 product_names, product_qtys, gst_percentage)
        else
            retail_line_items(discount_rate, discounted_unit_price, discounted_ex_gst_unit_price,\
                              inc_gst_shipping_price, ex_gst_shipping_price, order_id, order_products, order.total_inc_tax,\
                              product_names, product_qtys, gst_percentage)
        end
    end

    def retail_line_items(discount_rate, discounted_unit_price, discounted_ex_gst_unit_price,\
                          inc_gst_shipping_price, ex_gst_shipping_price, invoice_number, order_products, order_total,\
                          product_names, product_qtys, gst_percentage)

        line_amount_ex_taxes = {}
        discounted_ex_gst_unit_price.each { |op_id, d| line_amount_ex_taxes[op_id] = d * product_qtys[op_id] }

        line_amounts_ex_taxes_rounded = {}
        discounted_ex_gst_unit_price.each { |op_id, d| line_amounts_ex_taxes_rounded[op_id] = d.round(2) * product_qtys[op_id] }

        line_amount_total_ex_taxes = line_amount_ex_taxes.values.sum
        line_amounts_total_ex_taxes_rounded = line_amounts_ex_taxes_rounded.values.sum

        total_ex_gst = ex_gst_shipping_price + line_amounts_total_ex_taxes_rounded

        gst_line_amounts = {}
        line_amounts_ex_taxes_rounded.each { |op_id, d| gst_line_amounts[op_id] = get_gst_price(d, gst_percentage).round(2) }

        gst_sum_line_amounts = 0.00
        gst_sum_line_amounts += gst_line_amounts.values.sum.round(2)

        gst_on_shipping = get_gst_price(ex_gst_shipping_price.round(2), gst_percentage)

        gst_sum_line_amounts += gst_on_shipping
        gst_sum_line_amounts = gst_sum_line_amounts.round(2)

        total_inc_gst = total_ex_gst + gst_sum_line_amounts
        rounding_error_inc_gst = order_total - total_inc_gst

        rounding_error_ex_gst = get_ex_gst_price(rounding_error_inc_gst, gst_percentage).round(4)

        order_products.each do |op|
            op_id = op.id
            product_id = op.product_id
            product_name = product_names[op_id]
            XeroCalculation.insert_line_items_retail(invoice_number, product_id, product_name, op.qty,\
                                                     op.price_inc_tax, discount_rate, discounted_unit_price[op_id],\
                                                     discounted_ex_gst_unit_price[op_id], line_amount_ex_taxes[op_id],\
                                                     line_amounts_ex_taxes_rounded[op_id], gst_line_amounts[op_id], order_total)
        end

        XeroCalculation.insert_shipping_calculation(invoice_number, inc_gst_shipping_price,\
                                                    ex_gst_shipping_price, gst_on_shipping)

        # XeroCalculation.insert_gst(invoice_number, gst_sum_line_amounts)

      #   unless rounding_error_ex_gst.round(2) == 0.0
      #       XeroCalculation.insert_rounding(invoice_number,\
      #                                       total_ex_gst, gst_sum_line_amounts, order_total,\
      #                                       rounding_error_inc_gst, rounding_error_ex_gst)
      # end
    end

    def wholesale_line_items(discount_rate, discounted_unit_price, discounted_ex_gst_unit_price,\
                             inc_gst_shipping_price, ex_gst_shipping_price, invoice_number, order_products, order,\
                             product_names, product_qtys, gst_percentage)

        order_total = order.total_inc_tax
        wet_percentage = TaxPercentage.wet_percentage
        ship_charge_percentage = TaxPercentage.ship_charge_percentage

        discounted_ex_taxes_unit_price = {}
        discounted_ex_gst_unit_price.each { |op_id, d| discounted_ex_taxes_unit_price[op_id] = get_ex_taxes_price(d, wet_percentage) }

        line_amount_ex_taxes = {}
        discounted_ex_taxes_unit_price.each { |op_id, d| line_amount_ex_taxes[op_id] = d * product_qtys[op_id] }

        line_amounts_ex_taxes_rounded = {}
        discounted_ex_taxes_unit_price.each { |op_id, d| line_amounts_ex_taxes_rounded[op_id] = d.round(2) * product_qtys[op_id] }

        line_amount_total_ex_taxes = line_amount_ex_taxes.values.sum
        line_amounts_total_ex_taxes_rounded = line_amounts_ex_taxes_rounded.values.sum

        wet_unadjusted_order_product_price = {}
        line_amounts_ex_taxes_rounded.each { |op_id, d| wet_unadjusted_order_product_price[op_id] = wet_unadjusted_order_product(d, wet_percentage) }

        wet_unadjusted_total = wet_unadjusted_order_product_price.values.sum

        ship_deduction = calculate_ship_deduction(order.qty, ship_charge_percentage, gst_percentage)

        subtotal_ex_gst = (get_ex_gst_price(order_total, gst_percentage) - ex_gst_shipping_price - ship_deduction)

        wet_adjusted = (subtotal_ex_gst - get_ex_taxes_price(subtotal_ex_gst, wet_percentage))

        adjustment = (wet_unadjusted_total - wet_adjusted)

        total_ex_gst = line_amounts_total_ex_taxes_rounded + wet_adjusted.round(2) + adjustment.round(2) + ex_gst_shipping_price.round(2)

        gst_line_amounts = {}
        line_amounts_ex_taxes_rounded.each { |op_id, d| gst_line_amounts[op_id] = get_gst_price(d, gst_percentage).round(2) }

        gst_sum_line_amounts = 0.00
        gst_sum_line_amounts += gst_line_amounts.values.sum.round(2)

        gst_on_wet = get_gst_price(wet_adjusted.round(2), gst_percentage)
        gst_on_adjustment = get_gst_price(adjustment.round(2), gst_percentage)
        gst_on_shipping = get_gst_price(ex_gst_shipping_price.round(2), gst_percentage)

        gst_sum_line_amounts += gst_on_wet
        gst_sum_line_amounts = gst_sum_line_amounts.round(2)

        gst_sum_line_amounts += gst_on_adjustment
        gst_sum_line_amounts = gst_sum_line_amounts.round(2)

        gst_sum_line_amounts += gst_on_shipping
        gst_sum_line_amounts = gst_sum_line_amounts.round(2)

        total_inc_gst = total_ex_gst + gst_sum_line_amounts
        rounding_error_inc_gst = order_total - total_inc_gst

        rounding_error_ex_gst = get_ex_gst_price(rounding_error_inc_gst, gst_percentage).round(4)

        order_products.each do |op|
            op_id = op.id
            product_id = op.product_id
            product_name = product_names[op_id]

            XeroCalculation.insert_line_items_ws(invoice_number, product_id, product_name,\
                                                 op.qty, op.price_inc_tax, discount_rate, discounted_unit_price[op_id],\
                                                 discounted_ex_gst_unit_price[op_id], discounted_ex_taxes_unit_price[op_id],\
                                                 line_amount_ex_taxes[op_id], line_amounts_ex_taxes_rounded[op_id],\
                                                 gst_line_amounts[op_id], wet_unadjusted_order_product_price[op_id])
        end

        # XeroCalculation.insert_wet_calculation(invoice_number, wet_unadjusted_total, ship_deduction,\
        #                                        subtotal_ex_gst, wet_adjusted, gst_on_wet)
        #
        # XeroCalculation.insert_adjustment(invoice_number, adjustment, gst_on_adjustment)

        XeroCalculation.insert_shipping_calculation(invoice_number, inc_gst_shipping_price,\
                                                    ex_gst_shipping_price, gst_on_shipping)

        # XeroCalculation.insert_gst(invoice_number, gst_sum_line_amounts)
        #
        # unless rounding_error_ex_gst.round(2) == 0.0
        #     XeroCalculation.insert_rounding(invoice_number,\
        #                                     total_ex_gst, gst_sum_line_amounts, order_total, rounding_error_inc_gst, rounding_error_ex_gst)
        # end
    end

    def get_discount_rate(order)
        order_total_ex_shipping = order.total_inc_tax - order.shipping_cost_inc_tax
        order_product_total = OrderProduct.order_sum(order.order_products)
        order_total_ex_shipping / order_product_total
    end

    def get_ex_gst_price(inc_gst_price, gst_percentage)
        inc_gst_price / (1 + (gst_percentage / 100))
    end

    def get_gst_price(ex_gst_price, gst_percentage)
        ex_gst_price * (gst_percentage / 100)
    end

    def get_inc_gst_price(ex_gst_price, gst_percentage)
        ex_gst_price * (1 + gst_percentage / 100)
    end

    # But only if customer type is Retail
    def get_ex_taxes_price(ex_gst_price, wet_percentage)
        ex_gst_price / (1 + (wet_percentage / 100))
    end

    def wet_unadjusted_order_product(line_amount_ex_taxes_rounded, wet_percentage)
        line_amount_ex_taxes_rounded * (wet_percentage / 100)
    end

    def calculate_ship_deduction(qty, ship_charge_percentage, gst_percentage)
        ship_charge = ship_charge_percentage / 100
        ex_gst_ship_charge = get_ex_gst_price(ship_charge, gst_percentage)
        qty * ex_gst_ship_charge
    end

    def create_in_xero(order, contact_id)
        xero = XeroConnection.new.connect

        invoice_number = order.id
        contact = XeroContact.get_contact_from_xero(contact_id)

        invoice = xero.Invoice.build(invoice_number: invoice_number.to_s, contact: contact,\
                                     type: 'ACCREC', date: order.date_created.to_date,\
                                     due_date: 30.days.since(order.date_created.to_date),\
                                     status: 'SUBMITTED', line_amount_types: 'Exclusive')

        line_items = XeroCalculation.get_line_items(invoice_number)

        line_items.each do |l|
            next if ((l.item_code.to_i.to_s != l.item_code) && (l.unit_price_inc_tax == 0))

            item_code = l.item_code.to_s

            create_item(item_code)

            # unit_amount_clean = l.discounted_ex_taxes_unit_price.to_s.to_f.round(4)
            # unit_amount_clean = (unit_amount_clean / l.discount_rate) * (TaxPercentage.wet_percentage * 0.01 + 1) if l.item_code.to_i.to_s == l.item_code && l.account_code == '2100'
            # unit_amount_clean = (unit_amount_clean / l.discount_rate) * (TaxPercentage.gst_percentage * 0.01 + 1) if l.item_code.to_i.to_s == l.item_code && l.account_code == '2200'
            unit_amount = l.discounted_unit_price.to_s.to_f.round(4)
            invoice.add_line_item(item_code: item_code, description: l.description,\
                                  quantity: l.qty, unit_amount: unit_amount,\
                                  tax_type: l.tax_type.to_s, account_code: l.account_code.to_s)
        end
        invoice.save
      end

    # Item code must be a string
    def create_item(item_code)
        xero = XeroConnection.new.connect

        if xero.Item.all(where: 'code == "%s"' % item_code).empty?
            new_item = xero.Item.build(code: item_code)
            new_item.save
        end
     end

		#  update invoice in xero
    # DON'T USE
		def update_in_xero(order)
			xero = XeroConnection.new.connect

			invoice = xero.Invoice.find(order.xero_invoice_id)
			new_invoice = xero.Invoice

			if invoice.nil?
				return
			end

			# TODO update xero Calculation table
			XeroCalculation.get_line_items(order.id).destroy_all
			XeroInvoiceLineItem.where("xero_invoice_line_items.xero_invoice_id = '#{invoice.id}'").destroy_all

			invoice_line_items(order)


			new_line_items = XeroCalculation.get_line_items(order.id)
			new_line_items.each do |l|
					item_code = l.item_code.to_s

					create_item(item_code)

					unit_amount_clean = l.discounted_ex_taxes_unit_price.to_s.to_f.round(4)

					new_invoice.add_line_item(item_code: item_code, description: l.description,\
																quantity: l.qty, unit_amount: unit_amount_clean,\
																tax_type: l.tax_type.to_s, account_code: l.account_code.to_s)
			end
			invoice.line_items = new_invoice.line_items
			invoice.save

		end
end
