# helper for product controller
module ProductHelper
  def customer_pending_amount(product_ids, params, customer_ids)
    customer_pendings_hash = {}
    customer_pendings = OrderProduct.joins(:order).select('orders.customer_id, sum(order_products.qty) AS qty').where('orders.status_id = 1').product_filter(product_ids).group('orders.customer_id')
    customer_pendings = sort_pending_stock(customer_pendings, params[:order_col], params[:direction])
    customer_id_sort = []
    customer_pendings.each do |c_p|
      next unless customer_ids.include? c_p.customer_id
      customer_pendings_hash[c_p.customer_id] = c_p.qty
      customer_id_sort.append(c_p.customer_id)
    end
    customer_ids -= customer_id_sort
    customer_ids = customer_id_sort + customer_ids
    [customer_pendings_hash, customer_ids]
  end

  def sort_pending_stock(customer_pendings, order_col, direction)
    return customer_pendings if order_col != 'pending_stock'
    return customer_pendings.order('qty ASC') if direction != -1
    customer_pendings.order('qty DESC')
  end

  def monthly_average(sales_h, months)
    months = 1 if months.to_i == 0
    sales_h.values().sum/months
  end

  def monthly_supply(monthly_average, total_stock)
    return '--' if monthly_average == 0
    total_stock / monthly_average
  end

  def product_selection(params)
    selected = params.select{|key, value| value=='1'}.keys()
    unselected = params.select{|key, value| value=='0'}.keys()

    # Delete All unselected items
    # staffGroupItems_unselected
    staffGroupItems_unselected = StaffGroupItem.productNoWs(session[:default_group], unselected)
    staffGroupItems_unselected.delete_all unless staffGroupItems_unselected.blank?

    # Find the existing Products
    staffGroupItems = StaffGroupItem.productNoWs(session[:default_group], selected)
    # Insert New Products
    (selected - staffGroupItems.map(&:item_id)).each do |product_id|
      StaffGroupItem.new(staff_group_id: session[:default_group], item_id: product_id,\
        item_model: 'ProductNoWs').save
    end
    flash[:success] = "Updated Group #{StaffGroup.find(session[:default_group]).group_name}"
  end
end
