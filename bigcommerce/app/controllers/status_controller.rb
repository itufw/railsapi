require 'models_filter.rb'
require 'sales_controller_helper.rb'
require 'dates_helper.rb'
require 'time_period_stats.rb'
require 'status_helper.rb'
require 'fastway.rb'
require 'order_status.rb'
require 'application_helper.rb'
require 'order_helper.rb'

class StatusController < ApplicationController
  before_action :confirm_logged_in

  include ModelsFilter
  include SalesControllerHelper
  include DatesHelper
  include TimePeriodStats
  include StatusHelper
  include OrderStatus
  include ApplicationHelper
  include OrderHelper

  PACK_06 = 6
  PACK_12 = 12

  def pending
    @status_id, @status_name = get_id_and_name(params)
    staff_id, @staff = staff_filter(params)
    product_filtered_ids, @producer_country, @product_sub_type, @search_text = \
      products(params, staff_id, @status_id)
    @per_page, @orders, @products, @last_order_date = \
      orders(params, product_filtered_ids, staff_id, @status_id)
  end

  def status_check
    @status_name = params[:status_name]
    order_function, direction = sort_order(params, :order_by_id, 'ASC')
    per_page = params[:per_page] || Order.per_page

    if @status_name == 'Print'
      @staff, @status, orders, @search_text, @order_id = order_controller_filter(params, "display_report")
      @per_page, @orders = order_display_(params, orders)
    elsif @status_name == 'Problem'
      @orders = Order.problem_status_filter.send(order_function, direction).paginate(per_page: @per_page, page: params[:page])
    elsif @status_name == 'Courier'
      status_ids = Status.where("alt_name LIKE '%#{@status_name}%'").map(&:id)
      @orders = Order.statuses_filter(status_ids).courier_not_confirmed.send(order_function, direction).paginate(per_page: @per_page, page: params[:page])
      stock_label_status @orders
    elsif @status_name == 'ScotPac'
      @orders = Order.joins(:customer, :xero_invoice)
        .where('customers.cust_type_id = 2 AND status_id = 12 AND scot_pac_load IS NULL AND xero_invoices.amount_due > 0 AND (account_type NOT LIKE "COD" OR account_type IS NULL)')
        .paginate(per_page: @per_page, page: params[:page])
    else
      status_ids = Status.where("alt_name LIKE '%#{@status_name}%'").map(&:id)
      @orders = Order.statuses_filter(status_ids).send(order_function, direction).paginate(per_page: @per_page, page: params[:page])
    end

    @orders = [] if @orders.nil?
  end

  # vchar - get stock labels status to see if the number of labels is sufficient for all the
  # current all orders pending for delivery
  def stock_label_status orders
    required_labels = labels_of_orders orders

    @stock_status = fastway_stock_level()
    
    set_empty_label_to_zero()

    @stock_status.each do |label|
      case label['Colour']
        when 'RED6'
          label['Required'] = required_labels[:reds]
        when 'Red_Multi2'
          label['Required'] = required_labels[:redm]
        when 'RED'
          label['Required'] = required_labels[:redt]
        when 'BROWN'
          label['Required'] = required_labels[:brwt]
        when 'BROWN_MULTI2'
          label['Required'] = required_labels[:brwm]
        when 'LRG-FLAT-RATE-PARCEL'
          label['Required'] = required_labels[:prcl]
        else
          label['Required'] = 0
      end
    end
    @stock_status
  end

  # vchar - get total number of each label for all orders
  def labels_of_orders orders
    labels = {}

    # initialise a label colour 
    labels[:reds] = 0     # red 6
    labels[:redt] = 0     # red 12
    labels[:redm] = 0     # red multi
    labels[:brwt] = 0     # brown 12
    labels[:brwm] = 0     # brown multi
    # labels[:gryt] = 0     # grey 12
    # labels[:grym] = 0     # grey multi
    labels[:prcl] = 0     # parcel

    orders.each do |order|
      colour = Fastway.new.label_colour order

      # get order quantity
      qty = order.qty

      # get labels
      case colour
        when :red
          if qty > PACK_06
            labels[:redm] += ((qty - PACK_12) / PACK_12.to_f).ceil if qty > PACK_12
            labels[:redt] += 1  
          else
            labels[:reds] += 1
          end
        when :brown
          labels[:brwm] = ((qty - PACK_12) / PACK_12.to_f).ceil if qty > 12
          labels[:brwt] += 1
        else
          labels[:prcl] += (qty / PACK_12.to_f).ceil
      end
    end

    labels  # return the number of labels of each color
  end

  # TO BE IMPLEMENTED
  # vchar - initialise any labels which are not appearing in the stock lists
  def set_empty_label_to_zero 
  end

  def status_update
    #  In lib/order_status
    status, result = order_status_handler(params, order_params, session[:user_id])
    case status
    when 'print_pod'
      send_data result.to_pdf, filename: "Pod_#{session[:username]}_#{Date.today.to_s}.pdf" and return
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
    when 'export_scotpac'
      redirect_to controller: 'admin', action: 'scotpac_export', format: 'xlsx', selected_orders: result and return
    when 'scotpac_loaded'
      flash[:success] = 'Orders are Loaded!'
      redirect_to request.referrer and return
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
      :customer_purchase_order, :ship_name, :company, :street_2)
  end
