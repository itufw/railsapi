module OrderHelper
  def orders_page_title(staff_nickname, start_date, end_date)
    if start_date.nil? || start_date.blank?
      'Orders'
    else
      if staff_nickname.nil?
        "Orders from #{date_format_orders(start_date)} - #{date_format_orders(end_date.to_date.prev_day)}"
      else
        "Orders for #{staff_nickname} from #{date_format_orders(start_date)} - #{date_format_orders(end_date.to_date.prev_day)}"
      end
    end
  end

  def product_qty(product_ids, order_id)
    Order.order_filter_(order_id).order_product_filter(product_ids).sum_order_product_qty
  end

  def invoice_status(xero_invoice)
    XeroInvoice.paid(xero_invoice) || XeroInvoice.over(xero_invoice) \
    || XeroInvoice.unpaid(xero_invoice) \
    || XeroInvoice.partially_paid(xero_invoice) || [' ', ' ']
  end

  def order_controller_filter(params, _rights_col)
    staff, status, orders, search_text, order_id = order_filter(params, session[:user_id], 'product_rights')
    [staff, status, orders, search_text, order_id]
  end

  def order_display_(params, orders)
    order_function, direction = sort_order(params, :order_by_id, 'DESC')
    per_page = params[:per_page] || Order.per_page
    orders = orders.where('orders.customer_id != 0').include_all.send(order_function, direction).paginate(per_page: per_page, page: params[:page])
    [per_page, orders]
  end

  def order_creation(order_params, products_params, customer_params)
    wet = TaxPercentage.wet_percentage * 0.01
    handling_fee = TaxPercentage.handling_fee
    gst = TaxPercentage.gst_percentage * 0.01


    # 100XXXXX CMS orders
    order_id = Order.select('MAX(id) as id').first.id
    order_id = (order_id > 10000000) ? order_id + 1 : order_id + 10000001
    order = Order.new(order_params)

    customer = Customer.find(order.customer_id)

    order_attributes = {'id': order_id, 'staff_id': customer.staff_id,\
      'account_status': customer.account_approval(order.total_inc_tax),\
      'qty': products_params.values().map {|x| x['qty'].to_i }.sum, 'items_shipped': 0,\
      'wrapping_cost': 0, 'active': 1, 'date_created': Time.now.to_s(:db), 'source': 'Manual',\
      'courier_status_id': 1, 'status_id': 11, 'created_by': session[:user_id],\
      'last_updated_by': session[:user_id]}
    order.assign_attributes(order_attributes)

    order.handling_cost = order.qty * handling_fee
    order.save

    products_params.each do |keys, product_params|
      product = OrderProduct.new(product_params.permit(:product_id, :price_luc, :qty, :discount, :price_discounted))
      product_attributes = {'order_id': order.id, 'qty_shipped': 0,\
          'order_discount': order.discount_rate, 'price_handling': handling_fee, 'stock_previous': 0,\
          'display': 1, 'damaged': 0, 'created_by': session[:user_id], 'updated_by': session[:user_id]}
      product.assign_attributes(product_attributes)

      product.base_price = product.price_luc / (1 + wet)
      product.price_inc_tax = product.price_discounted * (1 + gst)
      product.price_wet = (product.price_discounted / (1 + wet) - handling_fee) * wet
      product.price_gst = product.price_discounted * gst
      product.stock_current = product.qty
      product.stock_incremental = product.qty

      product.save
    end

    order.customer.update_attributes(customer_params) unless customer_params.nil?
  end
end
