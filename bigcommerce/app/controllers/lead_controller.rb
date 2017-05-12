require 'lead_helper.rb'
class LeadController < ApplicationController
  before_action :confirm_logged_in
  include LeadHelper

  def all_leads
    @staffs = Staff.active_sales_staff.order_by_order
    @leads, @search_text = lead_filter(params)
  end

  def create_leads
    @customer_lead = CustomerLead.new
  end

  def edit_leads
    @lead_name = params[:lead_name]
    @customer_lead = CustomerLead.filter_by_id(params[:lead_id])
  end

  def create_leads_handler
    if params['customer_lead']['id']
      id = params['customer_lead']['id']
      @customer_lead = CustomerLead.filter_by_id(id)
    else
      @customer_lead = CustomerLead.new
    end
    p = c
    # TODO below
    if @customer_lead.update_attributes(lead_params)
      flash[:success] = 'Successfully Created.'
      redirect_to action: 'create_leads'
    else
      flash[:error] = 'Unsuccessful.'
      render 'create_leads'
    end
  end

  # -----------private --------------------
  private

  def lead_params
    params.require(:customer_lead).permit(:firstname, :lastname, :actual_name,\
                                          :staff_id, :cust_style_id, \
                                          :cust_group_id, :cust_type_id, \
                                          :address, :region)
  end
end
