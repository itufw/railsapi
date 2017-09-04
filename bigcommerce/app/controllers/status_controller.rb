require 'models_filter.rb'
require 'sales_controller_helper.rb'
require 'dates_helper.rb'
require 'time_period_stats.rb'
require 'status_helper.rb'
require 'fastway.rb'
require 'order_status.rb'
require 'application_helper.rb'

class StatusController < ApplicationController
  before_action :confirm_logged_in

  include ModelsFilter
  include SalesControllerHelper
  include DatesHelper
  include TimePeriodStats
  include StatusHelper
  include OrderStatus
  include ApplicationHelper

  def pending
    @status_id, @status_name = get_id_and_name(params)
    staff_id, @staff = staff_filter(params)
    product_filtered_ids, @producer_country, @product_sub_type, @search_text = \
      products(params, staff_id, @status_id)
    @per_page, @orders, @products, @last_order_date = \
      orders(params, product_filtered_ids, staff_id, @status_id)
  end

  # DON'T Use
  def order_status
    customer_ids = (params[:search].nil?) ? [] : Customer.search_for(params[:search]).pluck("id")
    per_page = params[:per_page] || Order.per_page
    order_function, direction = sort_order(params, :order_by_id, 'DESC')

    @orders = Order.where('status_id != 10').customer_filter(customer_ids)\
      .send(order_function, direction).paginate(per_page: @per_page, page: params[:page])
  end

  def status_check
    @status_name = params[:status_name]
    order_function, direction = sort_order(params, :order_by_id, 'ASC')
    per_page = params[:per_page] || Order.per_page

    # TODO
    # if @status_name == "Delivered"
    #   shipped_orders = Order.status_filter([2]).map(&:id)
    #   fastway_traces = FastwayTrace.where('Reference IN (?)', shipped_orders).order('Date DESC')
    #   other_ids = shipped_orders.reject {|x| fastway_traces.map(&:Reference).include? x}
    #
    #
    #
    #   @orders = Order.where('status_id IN (2, 12) AND id NOT IN (?)', undeliver_ids).send(order_function, direction).paginate(per_page: @per_page, page: params[:page])
    # else
    status_ids = Status.where("alt_name LIKE '%#{@status_name}%'").map(&:id)
    @orders = Order.statuses_filter(status_ids).send(order_function, direction).paginate(per_page: @per_page, page: params[:page])
    # end
  end

  def status_update
    #  In lib/order_status
    status, result = order_status_handler(params, order_params, session[:user_id])
    case status
    when 'print_picking_sheet'
      send_data result, filename: "picking_sheet_#{session[:username]}_#{Date.today.to_s}.pdf" and return
    when 'print_invoice'
      send_data result.to_pdf, filename: "Invoices_#{session[:username]}_#{Date.today.to_s}.pdf" and return
    when 'print_picking_slip'
      send_data result.to_pdf, filename: "picking_slip_#{session[:username]}_#{Date.today.to_s}.pdf" and return
    when 'Group Update'
      redirect_to controller: 'order', action: 'all' and return
    when 'Label Error'
      redirect_to controller: 'order', action: 'order_confirmation', order_id: result.first, selected_orders: result, status_id: params[:status_id] and return
    when 'Next'
      redirect_to controller: 'order', action: 'order_confirmation', order_id: result.first, selected_orders: result, status_id: params[:status_id] and return
    end
    redirect_to controller: 'order', action: 'all' and return
  end

  def summary_with_product
    @status_id, @status_name = get_id_and_name(params)
    @product_id = params[:product_id]
    @product_name = params[:product_name]
    @num_orders = params[:num_orders]
    @qty = params[:qty]
    @status_qty = params[:status_qty]
    @total = params[:total]

    staff_id, @staff = staff_filter(params)
    @per_page, @orders, @products, @last_order_date = \
      orders(params, @product_id, staff_id, @status_id)
    @overall_stats = overall_stats_(params)
  end

  def overall_stats_(params)
    @selected_period, @period_types = define_period_types(params)
    @result = overall_stats('Order.order_product_filter(%s).status_filter(%s)' % \
       [@product_id, @status_id], :sum_order_product_qty, @selected_period, nil)
  end

  def fetch_last_products
    orders = Order.where(customer_id: params[:customer_id]).order('updated_at DESC')
    @last_order = orders.first
    order_ids = orders.map(&:id)
    @ops = OrderProduct.where("order_id IN (?) AND created_at > ?", order_ids, (Date.today - 3.month).to_s(:db)).limit(10)
    respond_to do |format|
      format.js
    end
  end
end

private
  def order_params
    params.require(:order).permit(:id, :status_id, :courier_status_id,\
      :account_status, :address, :billing_address, :customer_notes,\
      :staff_notes, :delivery_instruction, :SpecialInstruction1, :SpecialInstruction2,\
      :SpecialInstruction3, :track_number,:street, :city, :state, :postcode, :country,\
      :customer_purchase_order, :ship_name)
  end
