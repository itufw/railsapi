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
    @lead_name = params[:lead_name]
    @customer_lead = CustomerLead.filter_by_id(params[:lead_id])
  end

  def create_leads_handler
    if CustomerLead.filter_by_name(lead_params[:actual_name]).count > 0
      flash[:error] = "Leads already exists"
      render :back
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
    if @customer_lead.update_attributes(lead_params)
      flash[:success] = 'Successfully Modified.'
      redirect_to action: 'all_leads'
    else
      flash[:error] = 'Unsuccessful.'
      render 'edit_leads', lead_name: lead_params[:actual_name], lead_id: id
    end
  end

  def summary
    @lead = CustomerLead.filter_by_id(params['lead_id'])
    @lead_name = @lead.actual_name
    # task section
    @activity = Task.joins(:staff).lead_tasks(@lead.id).expired?.order_by_id('DESC')
    @subjects = TaskSubject.filter_by_ids(@activity.map(&:subject_1).compact)
  end

  def zomato
    response = HTTParty.get('https://developers.zomato.com/api/v2.1/search?entity_id=259&entity_type=city&cuisines=1%2C%20151%2C%203%2C%20131%2C%20193%2C%20133%2C%20158%2C%20287%2C%20144%2C%2035%2C%20153%2C%20541%2C%20268%2C%2038%2C%2045%2C%20274%2C%20134%2C%20181%2C%20154%2C%2055%2C%20162%2C%2087%2C%20471%2C%2089%2C%20141%2C%20179%2C%20150%2C%2095%2C%20264', headers: {"user-key" =>'210cbff82e3ecf757c6914794e1ca953' })
  end

  # -----------private --------------------
  private

  def lead_params
    params.require(:customer_lead).permit(:firstname, :lastname, :actual_name,\
                                          :staff_id, :cust_style_id, \
                                          :cust_group_id, :cust_type_id, \
                                          :address, :region, :website)
  end
end
