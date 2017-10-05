module StockControl

  def sales_rate_update
    products = Product.where(retail_ws: 'WS')
    products.each{|product| sales_rate_update_product(product)}
  end

  def sales_rate_update_product(product)
    product_sales = product.order_products.valid_orders
    monthly_supply = 0
    # only calculate weight for month with sales
    weight = 0

    SaleRateTerm.standard_term.each do |term|
      next unless term.term.between?(1, 4)

      sales = product_sales.select{ |x| x.created_at.between?(Date.today-term.days_until.day, Date.today-term.days_from.day) }.map(&:qty).sum

      monthly_supply += (sales * 30 / (term.days_until - term.days_from).to_f) * term.weight if (term.days_until - term.days_from)>0
      weight += term.weight unless sales==0

      product.send("sale_term_#{term.term}=", sales.to_i)
    end
    product.monthly_supply = monthly_supply.zero? ? 0 : Product.where(product_no_ws_id: product.product_no_ws_id).sum(:inventory) * weight / monthly_supply.to_f
    product.save
  end

  def stock_calculation
    product_hash = {}
    products_no_ws = ProductNoWs.joins(:products)
     .select('product_no_ws.*, products.case_size as case_size, products.calculated_price AS price,
       products.retail_ws AS retail_ws, products.name as product_name, products.inventory as inventory,
       products.id as product_id, products.name_no_winery as name_no_winery,
       products.sale_term_1, products.monthly_supply')

    allocated_products = OrderProduct.joins(:order).select('product_id, SUM(order_products.qty) as qty')
      .where('orders.status_id': 1).group('product_id')

    products_no_ws.each do |p|
      # Separate Perth Stock
      next if p.product_name.include?'Perth'

      # initialise the hash
      product = (product_hash[p.id].nil?) ? {inventory: 0, allocated: 0} : product_hash[p.id]

      product[:name] = p.name_no_winery unless p.name_no_winery.nil?
      product[:inventory] += p.inventory
      product[:case_size] = p.case_size

      allocated = allocated_products.detect{|x| x.product_id==p.product_id}
      product[:allocated] += allocated.qty unless allocated.nil?

      if p.retail_ws=='R'
        product[:rrp] = (p.price * 1.1).round(2)
      elsif p.product_name.include?'WS'
        product[:ws_id] = p.product_id
        product[:luc] = (p.price * 1.29).round(2)
        product[:term_1] = p.sale_term_1
        product[:monthly_supply] = p.monthly_supply
      end

      product_hash[p.id] = product
    end
    product_hash.select{|key, value| value[:inventory]>0 }
  end
end
