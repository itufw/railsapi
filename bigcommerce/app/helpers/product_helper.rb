# helper for product controller
module ProductHelper
  def customer_pending_amount(product_ids, params, customer_ids)
    customer_pendings_hash = {}
    customer_pendings = OrderProduct.joins(:order).select('orders.customer_id, sum(order_products.qty) AS qty').where('orders.status_id = 1').product_filter(product_ids).group('orders.customer_id')
    customer_pendings = sort_pending_stock(customer_pendings, params[:order_col], params[:direction])
    customer_id_sort = []
    customer_pendings.each do |c_p|
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
end
