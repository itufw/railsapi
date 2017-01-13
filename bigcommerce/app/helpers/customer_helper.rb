module CustomerHelper

	def customer_filter_path
    	return current_page?(action: 'incomplete_customers') ? "incomplete_customers" : "all" 
  	end

  	def customer_type_name(customer)
    	customer.cust_type.name unless customer.cust_type_id.nil?
  	end

  	def customer_style_name(customer)
    	customer.cust_style.name unless customer.cust_style_id.nil?
  	end

  	def outstanding_customer(xero_contact)
    	XeroContact.get_accounts_receivable_outstanding(xero_contact)
  	end

  	def overdue_customer(xero_contact)
    	XeroContact.get_accounts_receivable_overdue(xero_contact)
  	end


end