module CustomerHelper
  def customer_filter_path
    current_page?(action: 'incomplete_customers') ? 'incomplete_customers' : 'all'
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

  def get_new_customers(params, customers, start_date, end_date)
    order_function, direction = sort_order(params, 'order_by_name', 'ASC')
    per_page = params[:per_page] || Customer.per_page
    customers = customers.filter_new_customer(start_date, end_date).include_all.send(order_function, direction).paginate(per_page: @per_page, page: params[:page])

    [per_page, customers]
  end

  def latest_orders(params, orders)
    order_function, direction = sort_order(params, :order_by_id, 'DESC')
    per_page = params[:per_page] || 5
    orders = orders.include_all.send(order_function, direction).paginate(per_page: per_page, page: params[:page])
    [orders, per_page]
  end
end
