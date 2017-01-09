# this module transforms data about all the products
# into data about product with no vintages, or product with no WS in the name, etc.
# presents data in the product table grouping by these transform columns.
module ProductVariations

    # Steps for a new transform column to work:
    # Should be as a column in the database
    # have a 'group by transform column' function in the Product model
    # add a string -> model-name key-value pair in the model_map
    # add order_by name function in the Model 
    def all_products_transform(transform_column, products)

    	stock_h = product_stock(transform_column, products)
	    price_h = product_price(transform_column, products)
	   	pending_stock_h = pending_stock(transform_column, products)
        name_h = name_(transform_column, products)
        #products_transformed = all_products(transform_column, products)
        return stock_h, price_h, pending_stock_h, name_h

	    # sorting by something other than name doesnt work
	    #@products = ProductNoVintage.where('id IN (?)', ids).send(order_function, direction).paginate( per_page: @per_page, page: params[:page])
    end

    def top_products_transform(transform_column, product_transformed_ids)
        #products = Product.filter_by_ids(product_ids)
        #price_h = product_price(transform_column, products)
        price_h = product_price_after_transformation(transform_column, product_transformed_ids)
        product_name_h = product_name(transform_column, product_transformed_ids)
        return price_h, product_name_h
    end

    # returns a hash like {transform_column_id => product_stock} for the 
    # given subset of products
    # transform_column_id can be product_id, product_no_vintage_id, etc.
    # if it is product_no_vintage_id then the product_stock is the sum of the stock
    # of individual products that are related to the product_no_vintage_id
    def product_stock(transform_column, products)
        transform_column = transform_column == "product_id" ? "id" : transform_column
    	stock_h = products.group(transform_column).sum(:inventory)
    end

    def product_price(transform_column, products)
    	# {product_no_vintage_id => avg price of WS }
    	price_h = products.product_price('group_by_' + transform_column)
    end

    # we have an array of product_no_vintage_ids
    # get product price from that
    def product_price_after_transformation(transform_column, product_transformed_ids)
        # we want something like where('products.product_no_vintage_id IN (?)', array)
        new_transform_column = transform_column == "product_id" ? "id" : transform_column
        where_query = "products." + new_transform_column + " IN (?)"
        products = Product.where(where_query, product_transformed_ids)
        price_h = products.product_price('group_by_' + transform_column)
    end

    def pending_stock(transform_column, products)
        transform_column = transform_column == "product_id" ? "id" : transform_column
    	pending_stock_h = products.pending_stock('products.'+ transform_column)
    end

    def product_name(transform_column, product_ids)
        model_map = { "product_no_vintage_id" => ProductNoVintage, "product_no_ws_id" => ProductNoWs,\
            "product_id" => Product }
        return model_map[transform_column].filter_by_ids(product_ids).pluck("id,name").to_h
    end

    # Given products and the transform column,
    # return all the rows from the database table that reprsents that transform column
    # for the given set of products
    def name_(transform_column, products)
        model_map = { "product_no_vintage_id" => ProductNoVintage, "product_no_ws_id" => ProductNoWs}
        if transform_column == "product_id"
            return products
        end
        ids_a = products.group(transform_column).pluck(transform_column)
        products_transformed = model_map[transform_column].filter_by_ids(ids_a).pluck("id, name").to_h
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


    # Give an array of product_ids corresponding to
    # a product_no_vintage_id/no_ws_id
    # def transform_product_ids(transform_column, transform_column_val)
    #     if transform_column == "product_no_vintage_id"
    #         return (Product.where(product_no_vintage_id: transform_column_val)).pluck("id")
    #     elsif transform_column == "product_no_ws_id"
    #         return (Product.where(product_no_ws_id: transform_column_val)).pluck("id")
    #     else
    #         return nil
    #     end
    # end

    # # Given an array of product ids
    # # and a bool value for sort_column_index and sort_column_stats
    # # Return a sorted hash with structure {product_id => [name, price, retail/ws]}
    # # You can either sort based on the name, price, or retail_ws
    # # Or you get a product_ids array that is sorted according to stats, then dont do anything
    # def sort_top_products_table(product_ids_a, sort_column_index, sort_column_stats)
    #     products_h = Hash.new

    #     # find details of each Product from the model
    #     # returns {product_id => Active record}
    #     products_out_of_order = Product.find(product_ids_a).group_by(&:id)
    #     # Arrange those rows in order of the way ids appear in product_ids_a
    #     products_in_order = product_ids_a.map { |id| products_out_of_order[id].first }

    #     # Create a hash using Product active records
    #     products_in_order.each do |product|
    #       products_h[product.id] = [product.name, product.calculated_price, product.retail_ws]
    #     end

    #     # Sort more if necessary
    #     if sort_column_stats.nil?
    #       return Hash[products_h.sort_by { |k,v| v[sort_column_index.to_i] }]
    #     end
    #     return products_h
    # end


    # # TO CHANGE

    # def total_stock_product(product_id, param_total_stock)
    #     product_no_ws_id = Product.no_ws_id(product_id)
    #     if product_no_ws_id.nil?
    #         return param_total_stock.to_i
    #     else
    #         similar_products = Product.products_with_same_no_ws_id(product_no_ws_id)
    #         inventory_sum = 0
    #         similar_products.each {|p| inventory_sum += p.inventory}
    #         pending_stock_sum = (Product.pending_stock(similar_products.pluck("id"))).values.sum
    #         return pending_stock_sum + inventory_sum
    #     end
    # end


end