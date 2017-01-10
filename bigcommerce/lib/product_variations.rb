# this module transforms data about all the products
# into data about product with no vintages, or product with no WS in the name, etc.
# presents data in the product table grouping by these transform columns.
module ProductVariations

    # Steps for a new transform column to work:
    # Should be as a column in the database
    # have a 'group by transform column' function in the Product model
    # add a string -> model-name key-value pair in the model_map
    # add order_by name function in the Model
    def transform_product_model(transform_column, products)

    	stock_h = product_stock(transform_column, products)
	    price_h = product_price(transform_column, products)
	   	pending_stock_h = pending_stock(transform_column, products)
        products_transformed = all_products(transform_column, products)
        return stock_h, price_h, pending_stock_h, products_transformed

	    # sorting by something other than name doesnt work
	    #@products = ProductNoVintage.where('id IN (?)', ids).send(order_function, direction).paginate( per_page: @per_page, page: params[:page])
    end

    def product_stock(transform_column, products)
    	stock_h = products.group(transform_column).sum(:inventory)
    end

    def product_price(transform_column, products)
    	# {product_no_vintage_id => avg price of WS }
    	price_h = products.product_price('group_by_' + transform_column)
    end

    def pending_stock(transform_column, products)
    	pending_stock_h = products.pending_stock('products.'+ transform_column)
    end

    def all_products(transform_column, products)
        model_map = { "product_no_vintage_id" => ProductNoVintage, "product_no_ws_id" => ProductNoWs}
        if transform_column == "id"
            return products
        end
        ids_a = products.group(transform_column).pluck(transform_column)
        products_transformed = model_map[transform_column].filter_by_ids(ids_a)
    end

    def checked_radio_button(transform_column)
        if transform_column == "product_no_vintage_id"
            return false, true, false
        elsif transform_column == "product_no_ws_id"
            return false, false, true
        else
            return true, false, false
        end
    end



    def transform_product_ids(transform_column, transform_column_val)
        if transform_column == "product_no_vintage_id"
            return (Product.where(product_no_vintage_id: transform_column_val)).pluck("id")
        elsif transform_column == "product_no_ws_id"
            return (Product.where(product_no_ws_id: transform_column_val)).pluck("id")
        else
            return nil
        end

    end

    def total_stock_product(product_id, param_total_stock)
        product_no_ws_id = Product.no_ws_id(product_id)
        if product_no_ws_id.nil?
            return param_total_stock.to_i
        else
            similar_products = Product.products_with_same_no_ws_id(product_no_ws_id)
            inventory_sum = 0
            similar_products.each {|p| inventory_sum += p.inventory}
            pending_stock_sum = (Product.pending_stock(similar_products.pluck("id"))).values.sum
            return pending_stock_sum + inventory_sum
        end
    end


end
