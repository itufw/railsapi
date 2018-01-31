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

  def invoice_status(xero_invoice, order = nil)
    return [order.account_status, order.account_status] if !order.nil? \
      && !order.account_status.nil? \
      && order.account_status!="Approved"

    XeroInvoice.paid(xero_invoice) || XeroInvoice.over(xero_invoice) \
      || XeroInvoice.unpaid(xero_invoice) \
      || XeroInvoice.partially_paid(xero_invoice) \
      || [' ', ' ']
  end

  def order_controller_filter(params, _rights_col)
    staff, status, orders, search_text, order_id = order_filter(params, session[:user_id], 'product_rights')
    [staff, status, orders, search_text, order_id]
  end

  # display orders of each staff in a certain period of time
  def order_display_(params, orders)
    order_function, direction = sort_order(params, :order_by_id, 'DESC')
    per_page = params[:per_page] || Order.per_page

    # DEPRECATED as it does not fit the purpose.
    orders = orders.where('orders.customer_id != 0').include_all.send(order_function, direction).paginate(per_page: per_page, page: params[:page])

    # turn this on causes errors on pagination when the Order page is loading
    # filter all orders of a staff for a certain period
    # orders = orders.includes(:status).where('statuses.valid_order = 1').references(:statuses).includes(:customer).where('customers.Staff_id=5').references(:customers).include_all.send(order_function, direction).paginate(per_page: per_page, page: params[:page])
    # orders = orders.includes(:status).where('statuses.valid_order = 1').references(:statuses).includes(:customer).where('customers.Staff_id=?', @staffs).include_all.send(order_function, direction).paginate(per_page: per_page, page: params[:page])
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
      product_id = product_params['product_id'].split('-').first
      # if product comes from allocated Order
      if product_params['product_id'].split('-').count>1
        allocated_product = OrderProduct.joins(:order).where('orders.customer_id': order.customer_id, 'orders.status_id': 1, product_id: product_id, qty: (1..500)).first

        allocated_product.assign_attributes(qty: allocated_product.qty - product_params[:qty].to_i,\
         stock_previous: allocated_product.qty, stock_current: allocated_product.qty - product_params[:qty].to_i,\
         stock_incremental: 0 - product_params[:qty].to_i, updated_by: session[:user_id],\
         display: ((allocated_product.qty - product_params[:qty].to_i)==0)? 0 : 1)

        allocated_product.save
        allocated_order = Order.where(customer_id: order.customer_id, status_id: 1).first
        allocated_order.update(qty: allocated_order.qty - product_params[:qty].to_i)
      end
      product = OrderProduct.new(product_params.permit(:price_luc, :qty, :discount, :price_discounted))
      product_attributes = {'product_id': product_id, 'order_id': order.id, 'qty_shipped': 0,\
        'base_price': product.price_luc / (1 + wet), 'stock_previous': 0, 'stock_current': product.qty,\
        'stock_incremental': product.qty, 'display': 1, 'damaged': 0, 'created_by': session[:user_id],\
        'order_discount': order.discount_rate, 'price_handling': handling_fee,\
        'price_inc_tax': product.price_discounted * (1 + gst),\
        'price_wet': (product.price_discounted / (1 + wet) - handling_fee) * wet,\
        'price_gst': product.price_discounted * gst, 'updated_by': session[:user_id],\
        'updated_at': Time.now.to_s(:db)}
      product.update_attributes(product_attributes)
      
      product.save
    end

    order.customer.update_attributes(customer_params) unless customer_params.nil?
  end
end
