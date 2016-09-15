module ApplicationHelper

  def title(page_title)
  	content_for(:title) { page_title }
  end

  def display_num(value)
	number_with_delimiter(number_with_precision(value, precision: 2))
  end

  def date_format(date)
  	date.to_date.strftime('%A %d/%m/%y')
  end

  def date_format_orders(date)
    date.to_date.strftime('%d/%m/%y')
  end

  def customer_name(customer)
    if customer.nil?
      return " "
    else
  	  Customer.customer_name(customer.actual_name, customer.firstname, customer.lastname)
    end
  end

  def order_status(status)
  	status.name
  end

  def staff_nickname(customer)
  	customer.staff.nickname unless customer.nil?
  end

  def paginate(model)
    will_paginate model unless model.count < 15
  end

  def exists_in_h(hash, key)
    if hash.has_key? key
      return hash[key]
    else
      return " "
    end
  end

end
