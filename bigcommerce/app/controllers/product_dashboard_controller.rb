require 'models_filter.rb'
require 'product_dashboard_helper.rb'
require 'dates.rb' 
require 'dashboard_math.rb'

class ProductDashboardController < ApplicationController

    before_action :confirm_logged_in

    include Dates
    include ModelsFilter
    include ProductDashboardHelper
    include DashboardMath



    def group_orders(params)
        @end_date = return_end_date(return_date_given(params))

        # num_periods is the current number of periods value, default is 13
        # periods is an array of all the possible number of periods, ranges from 3-15
        @num_periods, @periods = num_of_periods(params)
       
        # selected_period is current selected period - can be weekly, monthly, quarterly,
        # default is monthly
        # period_types is an array of all the valid period types
        @selected_period, @period_types = current_period_type(params)

        # sum function is the sum function defined in Order model that the user
        # wants orders to be summed by - can be order total, order qty, etc.
        # it is in the form of a symbol - like :sum_total
        # param_val is a string representing that function - like "Order Total"
        # sum_params is a list of strings representing sum functions
        sum_function, @param_val, @sum_params = sum_function_orders(params[:sum_param], "Bottles")

        # dates is an array of all dates - sorted
        # For example num_periods = 3, end_date = 5th oct and "monthly" as selected_period returns
        # [1st Aug, 1st Sep, 1st Oct, 6th Oct]
        # 6th Oct is the last date in the array and not 5th oct because
        # we want to calculate orders including 5th Oct, for that we need to give the next day
        dates = dates_a_for_periods(@num_periods, @end_date, @selected_period)
        # returns a hash like {week_num/month_num/quarter_num => [start_date, end_date]}
        @dates_paired = pair_dates(dates, @selected_period)

        # date_function is a symbol representing group_by function depending on the period_type
        # group_by functions for various period_types is defined in Order model -
        # for eg. group_by_week_created
        # Here we want to group orders by period_type and products in the order
        date_function = (period_date_functions(@selected_period)[2] + "_and_product_id").to_sym

        # check if the staff can only see their orders
        # or filter by the staff dropdown
        staff_id, @staff = staff_params_filter(params, session[:user_id])

        # filter by CUstomer Style dropdown
        cust_style_id, @cust_style = collection_param_filter(params, :cust_style, CustStyle)

        # Filter valid orders and group them by date_function and sum them by sum_function
        # returns a hash like { [period_date/dates, product_id] => qty }
        @qty_hash = Order.valid_order.date_filter(dates[0], dates[-1]).staff_filter(staff_id).\
        cust_style_filter(cust_style_id).send(date_function).send(sum_function)

        # extract all the ids from the hash
        @product_ids_a = product_ids_for_hash(@qty_hash)
    end

    def products_filter(products_unfiltered_a, params)
        order_function, direction = sort_order(params, 'order_by_name', 'ASC')

        @producer, @producer_region, @product_type, @producer_country,\
        @product_sub_type, products_filtered, @search_text, @product_sub_types, @producers,\
        @producer_regions = \
        product_dashboard_param_filter(params)

        @products = products_filtered.filter_by_ids_nil_allowed(products_unfiltered_a).send(order_function, direction)
        @pending_stock_h = Product.pending_stock(@products.pluck("id"))
    end

    def sales
        # First get the orders based on end_date, number of periods, staff, customer style
        # Get all the product ids in those orders
        products_unfiltered = group_orders(params)
        # Then filter products based on their winery, region, etc dropdowns
        # Merge the two sets of products together
        products_filter(products_unfiltered, params)
    end

end