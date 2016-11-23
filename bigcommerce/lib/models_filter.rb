module ModelsFilter

  def order_param_filter(params, session_staff_id)

  	search_text = params[:search]
    customer_ids = Customer.search_for(search_text).pluck("id") unless search_text.nil?

    staff_id, staff = staff_params_filter(params, session_staff_id)

  	status_id, status = status_params_filter(params)

  	start_date = params[:start_date]
  	end_date = params[:end_date]
    order_id_text = params[:order_id_search]

    if order_id_text.to_i > 0
      orders = Order.order_filter_by_ids([order_id_text.to_i])
    else
      orders = Order.date_filter(start_date, end_date).customer_filter(customer_ids).staff_filter(staff_id).status_filter(status_id)
    end
    #orders = Order.all

    return staff, status, orders, search_text, order_id_text
  end

  def staff_params_filter(params, session_staff_id)
    if reports_access_open(session_staff_id) == 0
      staff_id = session_staff_id
      staff = Staff.filter_by_id(session_staff_id)
      return staff_id, staff
    else
    	if (!params["staff"].nil? && !params["staff"]["id"].empty?)
    	  staff_id = params["staff"]["id"]
    	  staff = Staff.filter_by_id(staff_id)
    	  return staff_id, staff
      elsif !params["staff_id"].nil?
        staff_id = params["staff_id"]
        staff = Staff.filter_by_id(staff_id)
        return staff_id, staff   
    	else
    	  return nil, nil
    	end
    end
  end

  def status_params_filter(params)
    unless (params[:status].nil? or params[:status][:id].empty?)
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
    cust_style_id, cust_style = cust_style_param_filter(params)

    customers = Customer.staff_search_filter(search_text, staff_id).cust_style_filter(cust_style_id)

    return staff, customers, search_text, staff_id, cust_style

  end

  def top_customer_filter(customer_ids, sort_column_index, sort_column_stats)

    customers_h = Hash.new

    customers_out_of_order = Customer.include_staff.include_cust_style.find(customer_ids).group_by(&:id)

    customers_in_order = customer_ids.map { |id| customers_out_of_order[id].first }

    customers_in_order.each do |c|
      customers_h[c.id] = [Customer.customer_name(c.actual_name, c.firstname, c.lastname),\
       c.staff.nickname, c.cust_style_name]
    end
    
    if sort_column_stats.nil?
      return Hash[customers_h.sort_by { |k,v| v[sort_column_index.to_i] }]
    end

    return customers_h

  end

  def cust_style_param_filter(params)
    unless (params["cust_style"].nil? or params["cust_style"]["id"].empty?)
      cust_style_id = params["cust_style"]["id"]
      cust_style = CustStyle.filter_by_id(cust_style_id)
      return cust_style_id, cust_style
    else
      return nil, nil
    end
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

    if params.empty?
      return nil, nil, Product.all, nil
    else
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
  end

  def top_products_filter(product_ids_a, sort_column_index, sort_column_stats)

    products_h = Hash.new

    products_out_of_order = Product.find(product_ids_a).group_by(&:id)

    products_in_order = product_ids_a.map { |id| products_out_of_order[id].first }

    products_in_order.each do |product|
      products_h[product.id] = [product.name, product.calculated_price, product.retail_ws]
    end

    if sort_column_stats.nil?
      return Hash[products_h.sort_by { |k,v| v[sort_column_index.to_i] }]
    end

    return products_h
    
  end


  def reports_access_open(staff_id)
    display_val = (Staff.display_report(staff_id)).to_i
    return display_val
  end

  def sort_order(params, default_function, default_direction)
    if params[:order_function].nil?
     return default_function, default_direction
    else
      return params[:order_function], params[:direction]
    end
  end

end