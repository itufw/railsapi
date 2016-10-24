class XeroCalculation < ActiveRecord::Base

	def self.insert_shipping_calculation(invoice_number, shipping_inc_tax, shipping_ex_tax, gst)
		shipping_account = XeroAccountCode.shipping_revenue
		create(invoice_number: invoice_number, item_code: "SHIPPING",\
		 description: "Shipping Costs - Shipping - fastway", qty: 1, unit_price_inc_tax: shipping_inc_tax,\
		 discounted_ex_gst_unit_price: shipping_ex_tax, discounted_ex_taxes_unit_price: shipping_ex_tax.round(2),\
		 gst: gst,\
		 account_code: shipping_account.account_code, tax_type: shipping_account.tax_type)
	end

	def self.insert_wet_calculation(invoice_number, wet_unadjusted_total, ship_deduction,\
		subtotal_ex_gst, wet_adjusted, gst)
		wet_payable_account = XeroAccountCode.wet_payable

		create(invoice_number: invoice_number, item_code: "WET", description: "WET", qty: 1,\
			wet_unadjusted_total: wet_unadjusted_total, ship_deduction: ship_deduction,\
			subtotal_ex_gst: subtotal_ex_gst, wet_adjusted: wet_adjusted,\
			discounted_ex_taxes_unit_price: wet_adjusted.round(2),\
			gst: gst,\
			account_code: wet_payable_account.account_code, tax_type: wet_payable_account.tax_type)
	end

	def self.insert_adjustment(invoice_number, adjustment, gst)
		wholesale_account = XeroAccountCode.wholesale
		create(invoice_number: invoice_number, item_code: "ADJUSTMENT", description: "ADJUSTMENT",\
			qty: 1, adjustment: adjustment, discounted_ex_taxes_unit_price: adjustment.round(2),\
			gst: gst,\
			account_code: wholesale_account.account_code,\
			tax_type: wholesale_account.tax_type)
	end

	def self.insert_rounding(invoice_number, total_ex_gst, gst,\
        order_total, rounding_error_inc_gst, rounding_error_ex_gst)
		wholesale_account = XeroAccountCode.wholesale
		create(invoice_number: invoice_number, item_code: "ROUNDING", description: "ROUNDING",\
			qty: 1, discounted_ex_taxes_unit_price: rounding_error_ex_gst,\
			total_ex_gst: total_ex_gst, gst: gst,\
			order_total: order_total, rounding_error_inc_gst: rounding_error_inc_gst,\
			rounding_error: rounding_error_ex_gst,\
			account_code: wholesale_account.account_code,\
			tax_type: wholesale_account.tax_type)
	end

	def self.insert_line_items_ws(invoice_number, product_id, product_name, qty, op_unit_price,\
	    discount_rate, discounted_unit_price, discounted_ex_gst_unit_price,\
	    discounted_ex_taxes_unit_price, line_amount_ex_taxes, line_amount_ex_taxes_rounded,\
	    gst, wet_unadjusted_order_product_price)

		wholesale_account = XeroAccountCode.wholesale

		clean_product_name = ActiveSupport::Inflector.transliterate(product_name).to_s.gsub(/[^a-z ]/i, '')

		create(invoice_number: invoice_number, item_code: product_id.to_s,\
			description: clean_product_name, qty: qty, unit_price_inc_tax: op_unit_price,\
			discount_rate: discount_rate, discounted_unit_price: discounted_unit_price,\
			discounted_ex_gst_unit_price: discounted_ex_gst_unit_price,\
			discounted_ex_taxes_unit_price: discounted_ex_taxes_unit_price.round(2),\
			line_amount_ex_taxes: line_amount_ex_taxes,\
			line_amount_ex_taxes_rounded: line_amount_ex_taxes_rounded,\
			gst: gst,\
			wet_unadjusted_order_product_price: wet_unadjusted_order_product_price,\
			account_code: wholesale_account.account_code,\
			tax_type: wholesale_account.tax_type)
	end

	def self.insert_line_items_retail(invoice_number, product_id, product_name, qty,\
		op_unit_price, discount_rate, discounted_unit_price, discounted_ex_gst_unit_price,\
		line_amount_ex_taxes, line_amount_ex_taxes_rounded, gst, order_total)
		retail_account = XeroAccountCode.retail

		clean_product_name = ActiveSupport::Inflector.transliterate(product_name).to_s.gsub(/[^a-z ]/i, '')
		
		create(invoice_number: invoice_number, item_code: product_id.to_s,\
			description: clean_product_name, qty: qty, unit_price_inc_tax: op_unit_price,\
			discount_rate: discount_rate, discounted_unit_price: discounted_unit_price,\
			discounted_ex_gst_unit_price: discounted_ex_gst_unit_price,\
			discounted_ex_taxes_unit_price: discounted_ex_gst_unit_price.round(2),\
			line_amount_ex_taxes: line_amount_ex_taxes,\
			line_amount_ex_taxes_rounded: line_amount_ex_taxes_rounded,\
			gst: gst, order_total: order_total,\
			account_code: retail_account.account_code,\
			tax_type: retail_account.tax_type)\
	end

	def self.get_line_items(invoice_number)
		where(invoice_number: invoice_number)
	end

end
