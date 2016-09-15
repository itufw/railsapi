module ModelsFilter

  def order_param_filter(params)

  	search_text = params[:search]
    customer_ids = Customer.search_for(search_text).pluck("id")

  	staff_val = staff_params_filter(params)
  	staff_id = staff_val[0]
  	staff = staff_val[1]

  	status_val = status_params_filter(params)
  	status_id = status_val[0]
  	status = status_val[1]

  	start_date = params[:start_date]
  	end_date = params[:end_date]

  	orders = Order.include_customer_staff_status.date_filter(start_date, end_date).customer_filter(customer_ids).staff_filter(staff_id).status_filter(status_id)
  	return staff, status, orders

  end

  def staff_params_filter(params)
  	if !params[:staff].nil? && !params[:staff][:id].empty?
  	  staff_id = params[:staff][:id]
  	  staff = Staff.filter_by_id(staff_id)
  	  return staff_id, staff
  	else
  	  return nil, nil
  	end
  end

  def status_params_filter(params)
  	if !params[:status].nil? && !params[:status][:id].empty?
  	  status_id = params[:status][:id]
  	  status = Status.filter_by_id(status_id)
  	  return status_id, status
  	else
  	  return nil, nil
  	end
  end

  def customer_param_filter

  end

  def product_param_filter

  end

end