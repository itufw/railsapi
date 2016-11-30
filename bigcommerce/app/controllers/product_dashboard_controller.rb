require 'dates_helper.rb'  
require 'models_filter.rb'
require 'product_dashboard_helper.rb'

class ProductDashboardController < ApplicationController

    before_action :confirm_logged_in

    include DatesHelper
    include ModelsFilter
    include ProductDashboardHelper



    def product_sales(params)
        @end_date = return_end_date(return_date_given(params))
        if params[:num_period]
          @num_periods = params[:num_period].to_i
        else 
          @num_periods = 13
        end
        @periods = (3..15).to_a
        # This returns 
        @selected_period, @period_types = define_period_types(params)

        sum_function, @param_val, @sum_params = order_sum_param(params[:sum_param])
        if params[:sum_param].nil?
            sum_function, @param_val = :sum_qty,  "Bottles"
        end
        # periods_from_end_date is defined in Dates Helper
        # returns an array of all dates - sorted
        # For example num_periods = 3, end_date = 5th oct and "monthly" as period_type returns
        # [1st Aug, 1st Sep, 1st Oct, 6th Oct]
        # 6th Oct is the last date in the array and not 5th oct because
        # we want to calculate orders including 5th Oct, for that we need to give the next day
        dates = periods_from_end_date(@num_periods, @end_date, @selected_period)
        # returns a hash like {week_num/month_num => [start_date, end_date]}
        @dates_paired = pair_dates(dates, @selected_period)

        date_function = (period_date_functions(@selected_period)[2] + "_and_product_id").to_sym


        staff_id, @staff = staff_params_filter(params, session[:user_id])
        cust_style_id, @cust_style = collection_param_filter(params, :cust_style, CustStyle)

        @qty_hash = Order.valid_order.date_filter(dates[0], dates[-1]).staff_filter(staff_id).\
        cust_style_filter(cust_style_id).send(date_function).send(sum_function)

        @product_ids_a = product_ids_for_hash(@qty_hash)

    end

    def products_filter(products_unfiltered_a, params)
    order_function, direction = sort_order(params, 'order_by_name', 'ASC')

    @per_page = params[:per_page] || Product.per_page

    @producer, @producer_region, @product_type, @producer_country,\
    @product_sub_type, products_filtered, @search_text, @product_sub_types, @producers,\
    @producer_regions = \
    product_dashboard_param_filter(params)

    @products = Product.filter_by_ids(products_unfiltered_a & products_filtered.pluck("id")).send(order_function, direction)
    #@pending_stock_h = Product.pending_stock(@products.pluck("id"))
    end

    def sales
        products_unfiltered = product_sales(params)
        products_filter(products_unfiltered, params)
    end

end