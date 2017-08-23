require 'fastway.rb'
module OrderStatus

  def order_status_handler(params, order_params, user_id)
    selected_orders = params[:selected_orders] || []
    selected_orders = selected_orders.first.split unless selected_orders.blank? || selected_orders.count > 1

    # Print Shipping List
    if "Paperwork" == params[:commit] && !selected_orders.blank?
      # Print Picking Sheet
      # Due to Rails redirect conflicts
      pdf = print_shipping_sheet(selected_orders)
      return ['Paperwork', pdf]
    end

    case params[:commit]
    when 'Picked'
      Order.where(id: selected_orders).update_all(status_id: 8, last_updated_by: user_id)
      return ['Group Update', '']
    when 'Ready'
      Order.where(id: selected_orders).update_all(status_id: 9, last_updated_by: user_id)
      return ['Group Update', '']
    when 'Shipped'
      Order.where(id: selected_orders).update_all(status_id: 2, last_updated_by: user_id)
      return ['Group Update', '']
    when 'Approve'
      Order.find(params[:order_id]).update_attributes(order_params.merge({status_id: 3, last_updated_by: user_id}))
    when 'Hold-Stock'
      Order.find(params[:order_id]).update_attributes(order_params.merge({status_id: 20, last_updated_by: user_id}))
    when 'Hold-Price'
      Order.find(params[:order_id]).update_attributes(order_params.merge({status_id: 7, last_updated_by: user_id}))
    when 'Hold-Other'
      Order.find(params[:order_id]).update_attributes(order_params.merge({status_id: 13, last_updated_by: user_id}))
    when 'Delivered'
      Order.find(params[:order_id]).update_attributes(order_params.merge({status_id: 12, last_updated_by: user_id}))
    when 'Problem'
      Order.find(params[:order_id]).update_attributes(order_params)
    when 'Complete'
      Order.find(params[:order_id]).update_attributes(order_params.merge({status_id: 10, last_updated_by: user_id}))
    when 'Skip'
      # Just Skip
    when 'Create Label'
      # Create Fastway Label & Create tracking information for orders
      # IF order_params[:courier_status_id] == 3 -> Create FASTWAY Label
      # Else: just record the label number
      if order_params[:courier_status_id] == '3'
        order = Order.find(params[:order_id])
        order.update_attributes(order_params.reject{|key, value| key == 'courier_status_id' })
        result = Fastway.new.add_consignment(order, params['dozen'].to_i, params['half-dozen'].to_i)
        begin
          order.update_attributes(order_params.merge({track_number: result['result']['LabelNumbers'].join(';'), courier_status_id: 4, status_id: 2, date_shipped: Time.now.to_s(:db), last_updated_by: user_id}))
          flash[:success] = "Label Printed"
        rescue
          flash[:error] = 'Fail to connect Fastway, Check the Shipping Address'
          flash[:error] = result['error'] unless result.nil? || result[:error].nil?
          selected_orders.unshift(params[:order_id])
          return ['Label Error', selected_orders]
        end
        # create label with fastway
      else
        Order.find(params[:order_id]).update_attributes(order_params.merge({status_id: 2, courier_status_id: order_params['courier_status_id'], date_shipped: Time.now.to_s(:db), last_updated_by: user_id}))
      end
    else
      if !params[:order].nil?
        status = Status.find(params[:order][:status_id])
        order = Order.find(params[:order][:id])
        # Approved, Partially Paid, Unpaid, Paid, Hold-Accounts
        account_status = params[:order][:account_status]
        if account_status == "Hold-Account" && status.in_transit == 1
          flash[:error] = "Account Hold for Order#" + order.id.to_s
        else
          order.assign_attributes(params[:order].permit(:status_id, :account_status, :courier_status_id))
          order.save
        end
      end
    end

    return ['All', ''] if selected_orders.blank?
    ['Next', selected_orders]
  end

  def print_shipping_sheet(selected_orders)
    orders = Order.where(id: selected_orders)
    pdf = CombinePDF.new
    picking_slips = CombinePDF.new
    orders.each do |order|
      customer = Customer.find(order.customer_id)
      order_invoice = WickedPdf.new.pdf_from_string(
        render_to_string(
            :template => 'pdf/order_invoice.pdf',
            :locals => {order: order, customer: customer}
            )
        )
      pdf << CombinePDF.parse(order_invoice)

      packing_slip = WickedPdf.new.pdf_from_string(
        render_to_string(
            :template => 'pdf/packing_slip.pdf',
            :locals => {order: order, customer: customer}
            )
        )
      picking_slips << CombinePDF.parse(packing_slip)
    end
    picking_sheet = WickedPdf.new.pdf_from_string(
      render_to_string(
          template: 'pdf/picking_sheet.pdf',
          locals: {order_products: OrderProduct.where(order_id: selected_orders, display: 1) }
          )
      )

    pdf << picking_slips
    pdf << CombinePDF.parse(picking_sheet)
    pdf
  end
end