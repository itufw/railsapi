require 'contact_helper.rb'
require 'models_filter.rb'

class ContactController < ApplicationController
  before_action :confirm_logged_in
  autocomplete :customer, :actual_name, full: true

  include ContactHelper
  include ModelsFilter

  def all_contacts
    @search_text = params['search']
    @contact_role = params['role'].nil? ? nil : params['role'].first.last
    @per_page = params[:per_page] || CustContact.per_page
    staff_id, = collection_param_filter(params, :staff, Staff)
    staff_id = session[:user_id].to_s if staff_id.nil? && session[:authority] == "Sales Executive"

    @contacts = CustContact.filter_by_staff(staff_id).filter_by_role(@contact_role).search_for(@search_text).order_by_contacts('ASC').paginate(per_page: @per_page, page: params[:page])
  end

  def create_contact
    @customer_id = params[:customer_id]
    @customer_name = params[:customer_name]

    @contact = Contact.new
  end

  def contact_creation
    contact = Contact.new
    if contact.update_attributes(contact_params)
      cust_contact = CustContact.new
      cust_contact.update_attributes(cust_contact_params)
      cust_contact.contact_id = contact.id
      cust_contact.position = params['role'].nil? ? nil : params['role'].first.last
      cust_contact.save

      CustomerTag.create(name: contact.name.to_s + ', (Contact)', role: 'Contact', customer_id: contact.id)
    else
      flash[:error] = 'Unsuccessful.'
      redirect_to action: 'create_contact' && return
    end
    if params[:customer_id].nil? || params[:customer_id].blank? || params[:customer_id] == ""
      redirect_to action: 'all_contacts' && return
    else
      redirect_to controller: 'customer', action: 'summary', customer_id: params[:customer_id], customer_name: Customer.find(params[:customer_id]).actual_name
    end
  end

  def edit_contact
    contact_id = params[:contact_id]
    redirect_to :back && return if contact_id.nil?

    @contact = Contact.find(contact_id)
    @customer_count = 0
  end

  def contact_edition
    contact = Contact.find(params[:contact_id])
    if contact.update_attributes(contact_params)
      # contact Helper
      update_cust_contact(params, contact.id)
    else
      flash[:error] = 'Unsuccessful.'
      redirect_to :back && return
    end
    redirect_to action: 'summary', contact_id: contact.id
  end

  def summary
    contact_id = params[:contact_id]
    redirect_to :back && return if contact_id.nil?

    @contact = Contact.find(contact_id)
  end

  private
  def contact_params
    params.require(:contact).permit(:name, :personal_number,\
                                  :preferred_contact_number, :time_unavailable)
  end

  def cust_contact_params
    params.permit(:customer_id, :position, :title, :phone, :fax, :email,\
                  :receive_invoice, :receive_statement, :receive_portfolio,\
                  :key_sales, :key_accountant)
  end
end
