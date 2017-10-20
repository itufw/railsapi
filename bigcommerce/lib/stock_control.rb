module StockControl

  def sales_rate_update
    standard_term = SaleRateTerm.standard_term
    # products = Product.where(retail_ws: 'WS')
    products = Product.where(retail_ws: 'WS').group(:product_no_vintage_id)
    products.each{|product| sales_rate_update_product_no_vintage(product, standard_term)}

    StaffGroupItem.where(item_model: 'SaleRateTerm').map(&:staff_group).uniq.each do |staff_group|
      product_ids = staff_group.products(staff_group.id).map(&:item_id)
      products = Product.where(id: product_ids)
      special_term = SaleRateTerm.special_term(staff_group.id)

      products.each{|product| sales_rate_update_product(product, special_term)}
    end
  end

  def sales_rate_update_product_no_vintage(product, terms)
    if product.product_no_vintage_id.to_i==0
      sales_rate_update_product(product, terms)
      return
    end

    # Sale Rate based on no vintage products
    product_sales = OrderProduct.where(product_id: Product.where(product_no_vintage_id: product.product_no_vintage_id).map(&:id)).valid_orders

    monthly_supply = 0
    # only calculate weight for month with sales
    weight = 0

    terms.each do |term|
      next unless term.term.between?(1, 4)

      sales = product_sales.select{ |x| x.created_at.between?(Date.today-term.days_until.day, Date.today-term.days_from.day) }.map(&:qty).sum

      monthly_supply += (sales * 30 / (term.days_until - term.days_from).to_f) * term.weight if (term.days_until - term.days_from)>0
      weight += term.weight unless sales==0

      product.send("sale_term_#{term.term}=", sales.to_i)
    end

    unless monthly_supply.zero?
      products = Product.where(product_no_vintage_id: product.product_no_vintage_id)
      inventory = products.sum(:inventory)
      # include allocated product into monthly supply calculation
      allocated = OrderProduct.joins(:order).select('SUM(order_products.qty) as qty')
        .where('orders.status_id': 1, product_id: products.map(&:id)).first.qty.to_i

      inventory += allocated

      product.monthly_supply = inventory * weight / monthly_supply.to_f
    end
    product.save

    Product.where(product_no_vintage_id: product.product_no_vintage_id)
     .update_all(sale_term_1: product.sale_term_1, sale_term_2: product.sale_term_2,
       sale_term_3: product.sale_term_3, sale_term_4: product.sale_term_4,
       monthly_supply: product.monthly_supply)
  end


  def sales_rate_update_product(product, terms)
    # Sale Rate based on no vintage products
    # product_sales = OrderProduct.where(product_id: Product.where(product_no_vintage_id: product.product_no_vintage_id).map(&:id)).valid_orders
    # Sale Rate Based on Individual Product
    product_sales = product.order_products.valid_orders
    monthly_supply = 0
    # only calculate weight for month with sales
    weight = 0

    terms.each do |term|
      next unless term.term.between?(1, 4)

      sales = product_sales.select{ |x| x.created_at.between?(Date.today-term.days_until.day, Date.today-term.days_from.day) }.map(&:qty).sum

      monthly_supply += (sales * 30 / (term.days_until - term.days_from).to_f) * term.weight if (term.days_until - term.days_from)>0
      weight += term.weight unless sales==0

      product.send("sale_term_#{term.term}=", sales.to_i)
    end

    unless monthly_supply.zero?
      products = Product.where(product_no_ws_id: product.product_no_ws_id)
      inventory = products.sum(:inventory)
      # include allocated product into monthly supply calculation
      allocated = OrderProduct.joins(:order).select('SUM(order_products.qty) as qty')
        .where('orders.status_id': 1, product_id: products.map(&:id)).first.qty.to_i

      inventory += allocated

      product.monthly_supply = inventory * weight / monthly_supply.to_f
    end
    product.save
  end

  def stock_calculation
    product_hash = {}
    products_no_ws = ProductNoWs.joins(:products)
     .select('product_no_ws.*, products.case_size as case_size, products.calculated_price AS price,
       products.retail_ws AS retail_ws, products.name as product_name, products.inventory as inventory,
       products.id as product_id, products.name_no_winery as name_no_winery,
       products.sale_term_1, products.monthly_supply, products.current,
       order_1, order_2')

    allocated_products = OrderProduct.joins(:order).select('product_id, SUM(order_products.qty) as qty')
      .where('orders.status_id': 1).group('product_id')

    products_no_ws.each do |p|
      # Separate Perth Stock
      next if p.product_name.include?'Perth'

      # initialise the hash
      product = (product_hash[p.id].nil?) ? {inventory: 0} : product_hash[p.id]
      product[:order_total] = 0 unless product[:order_total].to_i!=0


      product[:name] = p.name_no_winery unless p.name_no_winery.nil?
      product[:inventory] += p.inventory
      product[:case_size] = p.case_size
      product[:order_total] = (p.order_1.to_i + p.order_2.to_f*0.1).to_f unless p.order_1.to_i==0

      allocated = allocated_products.detect{|x| x.product_id==p.product_id}
      product[:allocated] = 0 if !allocated.nil? && product[:allocated].nil?
      product[:allocated] += allocated.qty unless allocated.nil?

      if (p.retail_ws=='R')&&(!p.product_name.include?'DM')
        product[:rrp] = (p.price * 1.1).round(2)
      elsif p.product_name.include?'WS'
        product = product.merge({ws_id: p.product_id, luc: (p.price * 1.29).round(2),
          current: p.current})

        product[:term_1] = p.sale_term_1 unless p.sale_term_1.nil? || p.sale_term_1.zero?
        product[:monthly_supply] = p.monthly_supply.round(0) unless p.monthly_supply.nil? || p.monthly_supply.round(0).zero?
      end

      product_hash[p.id] = product
    end

    # color defination in axlsx file
    product_hash.select{|key, value| value[:inventory]>=120 }.each do |id, product|
      next if product[:luc].nil?
      if product[:luc].between?(0, 16) && product[:inventory]>=180
        product[:name_color] = 'green_cell'
      elsif product[:luc].between?(16, 22)
        product[:name_color] = 'lightgreen_cell'
      elsif product[:luc].between?(22, 35)
        product[:name_color] = 'orange_cell'
      elsif product[:luc].between?(35, 50)
        product[:name_color] = 'lightorange_cell'
      end
    end

    product_hash.select{|key, value| value[:inventory]>0 }
  end

  def portfolio_products
    products = Product.where('inventory > 0 AND name_no_winery IS NOT NULL AND product_type_id!=6 AND retail_ws LIKE "WS"').group(:product_no_ws_id)
    wet = TaxPercentage.wet_percentage * 0.01 + 1
    producer_country = ProducerCountry.all.order(:id).unshift(ProducerCountry.new(id: 0, name: nil, short_name: nil))
    product_size = ProductSize.all.order(:id).unshift(ProductSize.new(id: 0, name: nil))
    product_type = ProductType.all.order(:id).unshift(ProductType.new(id: 0, name: nil))
    product_sub_type = ProductSubType.all.order(:id).unshift(ProductSubType.new(id: 0, name: nil))
    producer_region = ProducerRegion.all.order(:id).unshift(ProducerRegion.new(id: 0, name: nil))
    producer = Producer.all.order(:id).unshift(Producer.new(id: 0, name: nil))

    portfolio_list = []


    products.each do |product|
      portfolio = {id: product.id, country: producer_country[product.producer_country_id.to_i].name,
        winery: producer[product.producer_id.to_i].name,
        name: product.name_no_ws, name_no_winery: product.name_no_winery,
        name_no_winery_no_vintage: product.name_no_winery_no_vintage,
        portfolio_name: product.vintage.to_s + "  " + product.name_no_winery_no_vintage,
        vol: product_size[product.product_size_id.to_i].name,
        case: product.case_size, wholesale: (product.case_size.to_i*product.calculated_price*wet).round(2),
        luc: (product.calculated_price*wet).round(2), variety: product_type[product.product_type_id.to_i].name,
        sub_type: product_sub_type[product.product_sub_type_id.to_i].name,
        region: producer_country[product.producer_country_id.to_i].short_name.to_s+', '+producer_region[product.producer_region_id.to_i].name.to_s }

      portfolio_list.append(portfolio)
    end
    portfolio_list
  end
end
