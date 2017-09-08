require 'lead_helper.rb'
# handle lead requests
# including create/edit
class LeadController < ApplicationController

  before_action :confirm_logged_in

  include LeadHelper

  def all_leads
    @per_page = params[:per_page] || CustomerLead.per_page
    @leads, @search_text = lead_filter(params, @per_page)
  end

  def update_lead_staff
    lead_id = params[:lead_id]
    staff_id = params[:staff_id]

    CustomerLead.staff_change(staff_id, lead_id)
    # render html: "#{customer_id}, #{staff_id}".html_safe
    flash[:success] = 'Staff Successfully Changed.'
    redirect_to request.referrer
  end

  def create_leads
    customer_name = params['customer_name']
    staff_id = params['staff_id']
    @staff = Staff.find(staff_id) unless staff_id.nil?

    @search_text = params[:search]
    if !@search_text.nil?
      @google_spots = grab_from_google(@search_text)
    elsif !customer_name.nil? && !staff_id.nil?
      query = customer_name + "near #{@staff.state}"
      @google_spots = grab_from_google(query)
    end

    @customer_lead_button = true
  end

  def fetch_lead
    @customer_lead, @spot = spot_details(params[:place_id], params[:staff_id] ) unless params[:place_id].nil?
    @customer_lead_button = true

    respond_to do |format|
      format.js
    end
  end

  def edit_leads
    @link_to_customer = params[:link_to_customer]
    @lead_name = params[:lead_name]
    @customer_lead = CustomerLead.filter_by_id(params[:lead_id])
  end

  def create_leads_handler
    if CustomerLead.filter_by_name(lead_params[:actual_name]).count > 0
      flash[:error] = "Leads already exists"
      redirect_to :back
      return
    end
    @customer_lead = CustomerLead.new
    lead_params[:firstname] = lead_params[:actual_name] if lead_params[:firstname].nil?
    if @customer_lead.update_attributes(lead_params)
      flash[:success] = 'Successfully Created.'
      CustomerTag.new.insert_lead(@customer_lead)
      # redirect_to action: 'all_leads'
      redirect_to controller: 'calendar', action: 'event_check_offline'
    else
      flash[:error] = 'Unsuccessful.'
      render 'create_leads'
    end
  end

  def edit_leads_handler
    id = params['customer_lead']['id']
    @customer_lead = CustomerLead.filter_by_id(id)
    if @customer_lead.update_attributes(lead_params) && params['customer_lead']['customer_id'] != ""
      flash[:success] = 'Linked Customer'
      customer = lead_link_customer(@customer_lead, params['customer_lead']['customer_id'], Time.now())
      redirect_to controller: 'customer', action: 'summary', customer_id: customer.id, customer_name: customer.actual_name
    elsif params['customer_lead']['customer_id'] != ""
      flash[:error] = 'Unsuccessful.'
      render 'edit_leads', lead_name: lead_params[:actual_name], lead_id: id
    else
      flash[:success] = 'Successfully Modified.'
      redirect_to action: 'all_leads'
    end
  end

  def summary
    @lead = CustomerLead.filter_by_id(params['lead_id'])
    @lead_name = @lead.actual_name
    @lead_id = @lead.id
    # task section
    @activity = Task.joins(:staff).lead_tasks(@lead.id).expired?.order_by_id('DESC')
    @subjects = TaskSubject.filter_by_ids(@activity.map(&:subject_1).compact)
  end

  def link_leads
    @leads = CustomerLead.select('customer_leads.id AS lead_id, customer_leads.actual_name AS lead_name, customers.id AS customer_id, customers.actual_name AS customer_name, customers.address AS customer_address, customer_leads.address AS address').joins("Left JOIN customers ON customer_leads.actual_name LIKE customers.actual_name").not_customer.where('customer_leads.actual_name IS NOT NULL AND customers.actual_name IS NOT NULL')
  end

  def turn_customer
    lead_link_customer(CustomerLead.find(params[:lead_id]), params[:customer_id])
    redirect_to action: 'link_leads'
  end

  def convert_to_customer
    customer = CustomerLead.find(params[:lead_id]).convert_to_customer
    redirect_to controller: 'customer', action: 'summary', customer_id: customer.id, customer_name: customer.actual_name
  end

  # -----------private --------------------
  private

  def lead_params
    params.require(:customer_lead).permit(:firstname, :lastname, :actual_name,\
      :staff_id, :cust_style_id, :cust_group_id, :cust_type_id, :address,\
      :region, :website, :featured_image, :google_place_id, :street, :city,\
      :state, :country)
  end
end
