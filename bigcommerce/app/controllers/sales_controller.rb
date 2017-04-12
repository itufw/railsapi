require 'sales_controller_helper'
require 'dates_helper'
require 'display_helper'
require 'models_filter'
require 'product_variations'
require 'sales_helper.rb'

class SalesController < ApplicationController

  before_action :confirm_logged_in

  include SalesControllerHelper
  include DatesHelper
  include DisplayHelper
  include ModelsFilter
  include ProductVariations
  include SalesHelper

        # Displays this week's and last week's total order sales
        # Also displays total order sales for this week divided by staff
    def sales_dashboard
        # Date selected by user , default is today's date
        date_given = return_date_given(params)

        @dates_this_week = this_week(date_given)
        @dates_last_week = last_week(@dates_this_week[0])
        @dates_last_two_week = last_week(@dates_last_week[0])


        sum_function, @param_val, @sum_params = order_sum_param(params[:sum_param])

        # returns a hashmap like { date => order_totals }
        @sum_this_week = sum_orders(@dates_this_week[0], @dates_this_week[-1], :group_by_date_created, sum_function, nil)
        @sum_last_week = sum_orders(@dates_last_week[0], @dates_last_week[-1], :group_by_date_created, sum_function, nil)
        @sum_last_two_week = sum_orders(@dates_last_two_week[0], @dates_last_two_week[-1], :group_by_date_created, sum_function, nil)

        # Order.date_filter(@dates_this_week[0], @dates_this_week[-1].next_day).valid_order.staff_filter(nil).send(:group_by_date_created).send(sum_function)
        # p= c

        @dates_paired_this_week = make_daily_dates_map(@dates_this_week)
        @dates_paired_last_week = make_daily_dates_map(@dates_last_week)
        @dates_paired_last_two_week = make_daily_dates_map(@dates_last_two_week)

        # returns a hashmap like { [staff_id, date] => order_totals }

        staff_id, @staff_nicknames = display_reports_for_sales_dashboard(session[:user_id])

        @staff_sum_this_week = sum_orders(@dates_this_week[0], @dates_this_week[-1], :group_by_date_created_and_staff_id, sum_function, staff_id)
        #@staff_nicknames = Staff.active_sales_staff.nickname.to_h
        @staff_sum_this_week

        vc_group_number = 17
        @cust_group_sum_this_week, @cust_group_name = cust_group_sales(vc_group_number, @dates_this_week[0], @dates_this_week[-1], "Vintage Cellars")

        @current_user = Staff.find(session[:user_id])
        @display_all = params[:display_all] || "No"

    end

    def get_current_end_date(params)
        @end_date = return_end_date(return_date_given(params))
    end

    def set_num_columns(params)
        # periods = columns
        # one period is a pair of start and end date.
        @end_date = return_end_date(return_date_given(params))
        if params[:num_period]
          @num_periods = params[:num_period].to_i
        else
          @num_periods = 6
        end
        # maximum number of columns allowed = 15, min = 3
        @periods = (3..15).to_a
        # This returns if we want to divide columns as weekly date periods, monthly, etc.
        @selected_period, @period_types = define_period_types(params)
    end

    # sets the sum_function for the dashboard
    # do we want the cell value to be product qty, average product qty, order total, etc.
    def set_sum_function(params, default_sum_function, default_display_string)
        sum_function, @param_val, @sum_params = order_sum_param(params[:sum_param])
        if params[:sum_param].nil?
            sum_function, @param_val = default_sum_function,  default_display_string
        end
        return sum_function
    end

    def date_pairs
        # periods_from_end_date is defined in Dates Helper
        # returns an array of all dates - sorted
        # For example num_periods = 3, end_date = 5th oct and "monthly" as period_type returns
        # [1st Aug, 1st Sep, 1st Oct, 6th Oct]
        # 6th Oct is the last date in the array and not 5th oct because
        # we want to calculate orders including 5th Oct, for that we need to give the next day
        @dates = periods_from_end_date(@num_periods, @end_date, @selected_period)
        # returns a hash like {week_num/month_num => [start_date, end_date]}
        @dates_paired = pair_dates(@dates, @selected_period)
    end

    def sales_dashboard_detailed
        get_current_end_date(params)
        set_num_columns(params)
        date_pairs

        # order_sum_param takes into account what the user wants to calculate - Bottles or Order Totals
        # order_sum_param is defined in Sales Controller Helper
        # Sum function returns :sum_qty or :sum_total
        # These functions are defined in the Order model
        sum_function, @param_val, @sum_params = order_sum_param(params[:sum_param])

        # sum_orders returns a hash like {date/week_num/month_num => sum} depending on the date_type
        # defined in Sales Controller Helper

        # date_type returns group_by_week_created or group_by_month_created
        date_function = period_date_functions(@selected_period)[2]
        @sums_by_periods = sum_orders(@dates[0], @dates[-1], date_function.to_sym, sum_function, nil)
        staff_id, @staff_nicknames = display_reports_for_sales_dashboard(session[:user_id])
        @staff_sum_by_periods = sum_orders(@dates[0], @dates[-1], (date_function + "_and_staff_id").to_sym, sum_function, staff_id)

        @current_user = Staff.find(session[:user_id])
        @display_all = params[:display_all] || "No"
    end

    def customer_dashboard
        get_current_end_date(params)
        set_num_columns(params)
        date_pairs

        sum_function, @param_val, @sum_params = order_sum_param(params[:sum_param])

        date_function = (period_date_functions(@selected_period)[2] + "_and_customer_id").to_sym

        @customer_sum_h = sum_orders(@dates[0], @dates[-1], date_function, sum_function, params[:staff_id])

        @customers = Customer.filter_by_ids(@customer_sum_h.keys.map {|k| k[0]})
    end

    def transform_products(params)
        @transform_column = params[:transform_column] || "product_no_vintage_id"
        @checked_id, @checked_no_vintage, @checked_no_ws = checked_radio_button(@transform_column)
    end

    def product_detailed_filter(params)
        @producer, @producer_region, @product_type, @producer_country,\
        @product_sub_type, products_filtered, @search_text, @product_sub_types, @producers,\
        @producer_regions = \
        product_dashboard_param_filter(params)
        return products_filtered.pluck("id")
    end

    def product_dashboard
        get_current_end_date(params)
        set_num_columns(params)
        # this sum function is then queried on the OrderProduct model
        sum_function = set_sum_function(params, :sum_qty, "Bottles")
        # we want to group by date and product_id
        date_function = (period_date_functions(@selected_period)[2] + "_and_product_id").to_sym

        transform_products(params)

        date_pairs
        # filter data based on dropdowns
        staff_id, @staff = staff_params_filter(params)
        cust_style_id, @cust_style = collection_param_filter(params, :cust_style, CustStyle)
        product_filtered_ids = product_detailed_filter(params)

        #price range
        @min_price = params['min_price']
        @max_price = params['max_price']

        #stock range
        @min_stock = params['min_stock']
        @max_stock = params['max_stock']

        #sales range
        @min_sales = params['min_sales']
        @max_sales = params['max_sales']

        # product_qty_h is a hash with structure {[product_id, date_id/date_ids] => qty}
        product_qty_h = OrderProduct.product_filter(product_filtered_ids).valid_orders.\
        date_filter_end_date(@dates[-1]).staff_filter(staff_id).\
        # date_filter(@dates[0], @dates[-1]).staff_filter(staff_id).\
        cust_style_filter(cust_style_id).send(date_function, @transform_column).send(sum_function)

        product_ids = []
        product_qty_h.each { |date_id_pair, v| product_ids.push(date_id_pair[0])}
        # @product_ids = @product_ids.uniq

        # get the array of valid product_id
        # this function is located in helpers -> sales_helper
        @product_ids, @price_h, @product_name_h, @inventory_h, @pending_stock_h, @product_qty_h = \
                                        filter_by_range(@transform_column, product_ids.uniq,[@min_price, @max_price],\
                                        [@min_stock,@max_stock],[@min_sales,@max_sales], product_qty_h)

        # sort based on the arrows
        # this function is located in helpers -> sales_helper
        @product_ids = sort_by_arrows(params, @price_h, @product_name_h, @inventory_h, @pending_stock_h,@product_qty_h,@product_ids)


        @checked_stats = ("stats".eql? params[:display_column]) ? true : false
        @checked_detailis = !@checked_stats

        # stats View!
        # helpers - > sales_helper
        @stats_info, @stats_sum = stats_info(@product_ids, @product_name_h, @transform_column, @inventory_h, @pending_stock_h) if @checked_stats
    end


end
