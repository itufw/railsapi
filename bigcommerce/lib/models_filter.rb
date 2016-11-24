module ModelsFilter

  def order_param_filter(params, session_staff_id)

    search_text = params[:search]
    customer_ids = Customer.search_for(search_text).pluck("id") unless search_text.nil?

    staff_id, staff = staff_params_filter(params, session_staff_id)

    status_id, status = collection_param_filter(params, :status, Status)

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

  def customer_param_filter(params, session_staff_id)
    search_text = params[:search]

    staff_id, staff = staff_params_filter(params, session_staff_id)
    cust_style_id, cust_style = collection_param_filter(params, :cust_style, CustStyle)

    customers = Customer.staff_search_filter(search_text, staff_id).cust_style_filter(cust_style_id)

    return staff, customers, search_text, staff_id, cust_style

  end

  def collection_param_filter(params, field, model)
    if !params[field].nil? && !params[field][:id].empty?
      field_id = params[field][:id] 
      field_val = model.find(field_id)
      return field_id, field_val
    else
      return nil, nil
    end

  end

  def product_param_filter(params)

    if params.empty?
      return nil, nil, Product.all, nil
    else
      search_text = params[:search]
      producer_country_id, producer_country = collection_param_filter(params, :producer_country, ProducerCountry)
      product_sub_type_id, product_sub_type = collection_param_filter(params, :product_sub_type, ProductSubType)
      products = Product.search(search_text).producer_country_filter(producer_country_id).sub_type_filter(product_sub_type_id)

      return producer_country, product_sub_type, products, search_text, producer_country_id
    end
  end

  def product_dashboard_param_filter(params, session_staff_id)

    if params.empty?
      return nil, nil, nil, nil, nil, nil, Product.all, nil, ProductSubType.all,\
       Producer.all, ProducerRegion.all, nil
    end

    staff_id, staff = staff_params_filter(params, session_staff_id)
    producer_id, producer = collection_param_filter(params, :producer, Producer)
    producer_region_id, producer_region = collection_param_filter(params, :producer_region, ProducerRegion)
    product_type_id, product_type = collection_param_filter(params, :product_type, ProductType)
    cust_style_id, cust_style = collection_param_filter(params, :cust_style, CustStyle)

    producer_country, product_sub_type, products, search_text, producer_country_id = product_param_filter(params)

    products_filtered = products.producer_filter(producer_id).staff_filter(staff_id).\
    cust_style_filter(cust_style_id).producer_region_filter(producer_region_id).\
    type_filter(product_type_id)

    product_sub_types, producers, producer_regions = change_product_collections(product_type_id, producer_country_id)

    return staff, producer, producer_region, product_type, producer_country,\
     product_sub_type, products_filtered, search_text, product_sub_types, producers, producer_regions, cust_style
  end

  def change_product_collections(product_type_id, country_id)
    product_sub_types = ProductSubType.product_type_filter(product_type_id)
    producers = Producer.country_filter(country_id)
    producer_regions = ProducerRegion.country_filter(country_id)
    return product_sub_types, producers, producer_regions
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