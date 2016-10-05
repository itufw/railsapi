module ModelsFilter

  def order_param_filter(params, session_staff_id)

  	search_text = params[:search]
    customer_ids = Customer.search_for(search_text).pluck("id")

    staff_id, staff = staff_params_filter(params, session_staff_id)

  	status_id, status = status_params_filter(params)

  	start_date = params[:start_date]
  	end_date = params[:end_date]
  	orders = Order.include_customer_staff_status.date_filter(start_date, end_date).customer_filter(customer_ids).staff_filter(staff_id).status_filter(status_id)
  	return staff, status, orders, search_text
  end

  def staff_params_filter(params, session_staff_id)
    if reports_access_open(session_staff_id) == 0
      staff_id = session_staff_id
      staff = Staff.filter_by_id(session_staff_id)
      return staff_id, staff
    else
    	if (!params[:staff].nil? && !params[:staff][:id].empty?)
    	  staff_id = params[:staff][:id]
    	  staff = Staff.filter_by_id(staff_id)
    	  return staff_id, staff
      elsif !params[:staff_id].nil?
        staff_id = params[:staff_id]
        staff = Staff.filter_by_id(staff_id)
        return staff_id, staff   
    	else
    	  return nil, nil
    	end
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

  def customer_param_filter(params, session_staff_id)
    search_text = params[:search]

    staff_id, staff = staff_params_filter(params, session_staff_id)

    customers = Customer.staff_search_filter(search_text, staff_id)

    return staff, customers, search_text

  end

  def producer_country_params_filter(params)
    if !params[:producer_country].nil? && !params[:producer_country][:id].empty?
      producer_country_id = params[:producer_country][:id]
      producer_country = ProducerCountry.filter_by_id(producer_country_id)

      return producer_country_id, producer_country
    else
      return nil, nil
    end
  end

  def product_sub_type_params_filter(params)
    if !params[:product_sub_type].nil? && !params[:product_sub_type][:id].empty?
      product_sub_type_id = params[:product_sub_type][:id]
      product_sub_type = ProductSubType.filter_by_id(product_sub_type_id)

      return product_sub_type_id, product_sub_type
    else
      return nil, nil
    end
  end

  def product_param_filter(params)
    search_text = params[:search]

    producer_country_val = producer_country_params_filter(params)
    producer_country_id = producer_country_val[0]
    producer_country = producer_country_val[1]

    product_sub_type_val = product_sub_type_params_filter(params)
    product_sub_type_id = product_sub_type_val[0]
    product_sub_type = product_sub_type_val[1]

    products = Product.search(search_text).producer_country_filter(producer_country_id).sub_type_filter(product_sub_type_id) 

    return producer_country, product_sub_type, products, search_text
  end

  def product_filter(product_ids_a)
    product_h = Product.filter_by_ids(product_ids_a).pluck("id,name").to_h

    product_h_sorted = Hash[product_h.sort_by { |k,v| v }]

    return product_h_sorted
  end

  def reports_access_open(staff_id)
    display_val = (Staff.display_report(staff_id)).to_i
    return display_val
  end

end