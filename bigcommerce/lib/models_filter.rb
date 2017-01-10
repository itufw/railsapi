module ModelsFilter

  # def order_param_filter(params, session_staff_id)

  #   search_text = params[:search]
  #   customer_ids = Customer.search_for(search_text).pluck("id") unless search_text.nil?

  #   staff_id, staff = staff_params_filter(params, session_staff_id)

  #   status_id, status = collection_param_filter(params, :status, Status)

  #   start_date = params[:start_date]
  #   end_date = params[:end_date]
  #   order_id_text = params[:order_id_search]

  #   if order_id_text.to_i > 0
  #     orders = Order.order_filter_by_ids([order_id_text.to_i])
  #   else
  #     orders = Order.date_filter(start_date, end_date).customer_filter(customer_ids).staff_filter(staff_id).status_filter(status_id)
  #   end
  #   #orders = Order.all

  #   return staff, status, orders, search_text, order_id_text
  # end

  def order_filter(params, session_staff_id, rights_col)

    rights_val = Staff.where(id: session_staff_id).pluck(rights_col).first

    # if rights_val is 0, then restrict by the staff_id in session
    # otherwise don't
    staff_id, staff = rights_val ? staff_params_filter(params) : staff_session_filter(session_staff_id)

    search_text = params[:search]
    order_id_text = params[:order_id_search]
    customer_ids = Customer.search_for(search_text).pluck("id") unless search_text.nil?

    status_id, status = collection_param_filter(params, :status, Status)

    if order_id_text.to_i > 0
      orders = Order.order_filter_by_ids([order_id_text.to_i])
    else
      orders = Order.date_filter(params[:start_date], params[:end_date]).customer_filter(customer_ids).staff_filter(staff_id).status_filter(status_id)
    end
    return staff, status, orders, search_text, order_id_text
  end

  def order_sum_param(selected)
    sum_params_h = {"Order Totals" => :sum_total, "Bottles" => :sum_qty,\
     "Number of Orders" => :count_orders, "Avg. Order Total" => :avg_order_total,\
      "Avg. Bottles" => :avg_order_qty}

    if selected.nil?
      return sum_params_h["Order Totals"], "Order Totals", sum_params_h.keys 
    else
      return sum_params_h[selected], selected, sum_params_h.keys
    end
  end

  def staff_params_filter(params)
    # case when params is like {}
    unless params["staff"].nil?
      # case when params is like {"staff" => {}}
      unless params["staff"]["id"].empty?
        # return staff_id, staff row
        return params["staff"]["id"], Staff.filter_by_id(params["staff"]["id"])
      end
    end

    # case when the structure of params is different
    # when does this happen? what pages?
    unless params["staff_id"].nil?
      return params["staff_id"], Staff.filter_by_id(params["staff_id"])
    end
    return nil, nil
  end

  def staff_session_filter(session_staff_id)
    if reports_access_open(session_staff_id) == 0
      return session_staff_id, Staff.filter_by_id(session_staff_id)
    end
    return nil, nil
  end

  # def customer_param_filter(params)
  #   search_text = params[:search]

  #   staff_id, staff = staff_params_filter(params)
  #   cust_style_id, cust_style = collection_param_filter(params, :cust_style, CustStyle)

  #   customers = Customer.staff_search_filter(search_text, staff_id).cust_style_filter(cust_style_id)

  #   return staff, customers, search_text, staff_id, cust_style
  # end

  def customer_filter(params, session_staff_id, rights_col)
    rights_val = Staff.where(id: session_staff_id).pluck(rights_col).first

    # if rights_val is 0, then restrict by the staff_id in session
    # otherwise don't
    staff_id, staff = rights_val ? staff_params_filter(params) : staff_session_filter(session_staff_id)

    search_text = params[:search]
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

  def product_dashboard_param_filter(params)

    if params.empty?
      return nil, nil, nil, nil, nil, Product.all, nil, ProductSubType.all,\
       Producer.all, ProducerRegion.all
    end

    producer_id, producer = collection_param_filter(params, :producer, Producer)
    producer_region_id, producer_region = collection_param_filter(params, :producer_region, ProducerRegion)
    product_type_id, product_type = collection_param_filter(params, :product_type, ProductType)

    producer_country, product_sub_type, products, search_text, producer_country_id = product_param_filter(params)

    products_filtered = products.producer_filter(producer_id).\
    producer_region_filter(producer_region_id).\
    type_filter(product_type_id)

    product_sub_types, producers, producer_regions = change_product_collections(product_type_id, producer_country_id)

    return producer, producer_region, product_type, producer_country,\
     product_sub_type, products_filtered, search_text, product_sub_types, producers,\
    producer_regions
  end

  def change_product_collections(product_type_id, country_id)
    product_sub_types = ProductSubType.product_type_filter(product_type_id)
    producers = Producer.country_filter(country_id)
    producer_regions = ProducerRegion.country_filter(country_id)
    return product_sub_types, producers, producer_regions
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
    direction_map = {"1" => 'ASC', "-1" => 'DESC'}
    order_function = params[:order_col] ? params[:order_col] : default_function
    direction = params[:direction] ? direction_map[params[:direction]] : default_direction
    return order_function, direction
  end

end