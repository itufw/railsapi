module OrderHelper

	def orders_page_title(staff_nickname, start_date, end_date)
	  	unless start_date.nil? || start_date.blank?
	  	  	unless staff_nickname.nil?
	  	  		return "Orders for #{staff_nickname} from #{date_format_orders(start_date)} - #{date_format_orders(end_date.to_date.prev_day)}"
	  	  	else
	  	  		return "Orders from #{date_format_orders(start_date)} - #{date_format_orders(end_date.to_date.prev_day)}"
	  	  	end
	  	else
	  	  	return "Orders"
	  	end
  	end

	def product_qty(product_ids, order_id)
    	return Order.order_filter_(order_id).product_filter(product_ids).sum_order_product_qty
  	end

  	 def invoice_status(xero_invoice)
    	return XeroInvoice.paid(xero_invoice) || XeroInvoice.unpaid(xero_invoice) \
    	|| XeroInvoice.partially_paid(xero_invoice) || [" ", " "]
  	end


end