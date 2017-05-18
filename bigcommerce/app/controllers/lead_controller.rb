require 'lead_helper.rb'
# handle lead requests
# including create/edit
class LeadController < ApplicationController
  before_action :confirm_logged_in
  include LeadHelper

  def all_leads
    @staffs = Staff.active_sales_staff.order_by_order
    @leads, @search_text = lead_filter(params)
  end

  def create_leads
    @customer_lead = CustomerLead.new
    @google_client = grab_from_google(params, @customer_lead)
  
    @customer_lead_button = true
  end

  def edit_leads
    @lead_name = params[:lead_name]
    @customer_lead = CustomerLead.filter_by_id(params[:lead_id])
  end

  def create_leads_handler
    @customer_lead = CustomerLead.new
    if @customer_lead.update_attributes(lead_params)
      flash[:success] = 'Successfully Created.'
      redirect_to action: 'all_leads'
    else
      flash[:error] = 'Unsuccessful.'
      render 'create_leads'
    end
  end

  def edit_leads_handler
    id = params['customer_lead']['id']
    @customer_lead = CustomerLead.filter_by_id(id)
    if @customer_lead.update_attributes(lead_params)
      flash[:success] = 'Successfully Modified.'
      redirect_to action: 'all_leads'
    else
      flash[:error] = 'Unsuccessful.'
      render 'edit_leads', lead_name: lead_params[:actual_name], lead_id: id
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
