module ApplicationHelper

  # Sets Title of a page
  def title(page_title)
  	content_for(:title) { page_title }
  end

  # Displays a number with 2 precision and with commas
  def display_num(value)
	number_with_delimiter(number_with_precision(value, precision: 2))
  end

  # Displays a date in the form 'Day of the week, Day/Month/Year'
  def date_format(date)
  	date.to_date.strftime('%a %d/%m/%y')
  end

  # Displays date in the form Day/Month/Year
  def date_format_orders(date)
    date.to_date.strftime('%d/%m/%y') unless date.nil?
  end

  # Takes a Customer Object as input, returns its name
  def customer_name(customer)
    if customer.nil?
      return " "
    else
  	  Customer.customer_name(customer.actual_name, customer.firstname, customer.lastname)
    end
  end

  # Returns name of Status
  def order_status(status)
  	status.name
  end

  # Returns Staff's nickname
  # Takes in a staff object as input
  def staff_nickname_direct(staff)
    staff.nickname unless staff.nil?
  end

  # Takes in a customer object as input and returns staff's nickname
  def staff_nickname(customer)
  	customer.staff.nickname unless customer.nil?
  end

  def staff_id_for_order(order)
    customer = order.customer unless order.nil?
    return customer.staff_id unless customer.nil?
  end

  # Paginates model unless the number of rows are less than 15
  # 15 is the paginate limit set in every model
  def paginate(model)
    will_paginate model unless model.count < 30
  end

  # Checks if key exists in hash
  # If yes returns the corresponding value for that key
  # Otherwise returns empty string
  def exists_in_h(hash, key)
    if hash.has_key? key
      return hash[key]
    else
      return " "
    end
  end

  def exists_in_h_int(hash, key)
    if hash.has_key? key
      return hash[key]
    else
      return 0
    end
  end

  def calculate_product_price(product_calculated_price, retail_ws)
    if retail_ws == 'WS'
      return product_calculated_price * 1.29
    else
      return product_calculated_price
    end

  end

  def convert_empty_string_to_int(val)
    if val.to_s.strip.empty?
      return 0
    else
      return val
    end
  end

  def sum_order_products_qty(order_products)
    sum = 0
    order_products.each do |op|
      sum += op.qty
    end
    return sum
  end

  def since_days(date_today, num_days)
    num_days.days.since(date_today)
  end

  def sum_values_of_hash(hash)
    return hash.values.sum
  end

  def outstanding_customer(xero_contact_id)
    XeroContact.get_accounts_receivable_outstanding(xero_contact_id)
  end

  def overdue_customer(xero_contact_id)
    XeroContact.get_accounts_receivable_overdue(xero_contact_id)
  end

  def invoice_status(order_id)
    invoice = XeroInvoice.filter_by_invoice_number(order_id)
    unless invoice.nil?
      amount_due = XeroInvoice.amount_due(invoice)
      if XeroInvoice.paid(invoice)
        return ["PAID", 0.0]
      elsif XeroInvoice.partially_paid(invoice)
        return ["PARTIALLY-PAID", amount_due]
      elsif XeroInvoice.unpaid(invoice)
        return ["UNPAID", amount_due]
      end
    end
    return [" ", " "]
  end

end
