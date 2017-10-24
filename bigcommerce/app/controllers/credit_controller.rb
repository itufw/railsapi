require 'abn_search.rb'

class CreditController < ApplicationController
  before_action :confirm_logged_in
  def credit_application

    @customer = Customer.find(params[:customer_id])
    if params[:credit_app_id].nil?
      @credit_app = CustomerCreditApp.new(customer_id: @customer.id, credit_application_version: 1,\
       trading_name: (@customer.company.to_s=="") ? @customer.actual_name : @customer.company,\
       street: @customer.street, street_2: @customer.street_2, city: @customer.city,\
       state: @customer.state, postcode: @customer.postcode)
   else
     @credit_app = CustomerCreditApp.find(params[:credit_app_id])
   end
  end

  def save_credit_app
    if credit_params[:id].to_s==""
      credit_app = CustomerCreditApp.new(credit_params)
    else
      credit_app = CustomerCreditApp.find(credit_params[:id])
      credit_app.assign_attributes(credit_params)
    end
    credit_app.save

    unless params[:contact_signed].nil?
      params[:contact_signed].values().select{|x| (x.keys().include?'contact_id') && (x['signed']=="1")}.each do |existed_contact|
        CustomerCreditAppSigned.new.credit_app_update(credit_app.id, existed_contact['contact_id'],\
         credit_app.customer_id, session[:user_id], 1)
      end
      params[:contact_signed].values().reject{|x| x.keys().include?'contact_id'}.each do |contact|
        new_contact = Contact.new(name: contact[:contact_name], customer_id: credit_app.customer_id,\
         personal_number: contact["phone"])
        new_contact.save

        # require cleafication to identify:
        # receive_statement	key_sales  receive_invoice  receive_portfolio  key_accountant
        # based on Director / Account / Buyer parameters
        cust_contact = CustContact.new(customer_id: credit_app.customer_id, contact_id: new_contact.id,\
         position: contact[:position], title: contact[:title], phone: contact[:phone], email: contact[:email])
        cust_contact.save

        if contact[:signed]=="1"
          CustomerCreditAppSigned.new.credit_app_update(credit_app.id, new_contact.id,\
           credit_app.customer_id, session[:user_id], 1)
        end
      end
    end

    unless params[:reference].nil?
      params[:reference].values().each do |reference|
        CustomerCreditAppReference.new.credit_app_update(credit_app.id, reference, credit_app.customer_id)
      end
    end

    redirect_to controller: 'customer', action: 'summary', customer_id: credit_app.customer_id, customer_name: credit_app.trading_name
  end

  def verify_abn
    if (params['abn'].to_s=="") || !([9, 11].include?params['abn'].to_s.length)
      @alert = "Not a valid ABN Number"
    else
      begin
        result = AbnSearch.new.search_by_abn(params['abn'])
        response = result.parsed_response['ABRPayloadSearchResults']['response']
        @alert = response['exception']['exceptionDescription'] unless response['exception'].nil?
        @business_entity = response['businessEntity201408']
      rescue
        @alert = 'Unknown Error, Contact Will'
      end
    end
    respond_to do |format|
      format.js
    end
  end

  def credit_list
    @customer = Customer.find(params[:customer_id])
    respond_to do |format|
      format.js
    end
  end
end

private

  def credit_params
    params.require(:customer_credit_app).permit(:company_name, :trading_name,\
     :phone,:fax, :abn, :current_premises, :street, :street_2, :city, :state,\
     :postcode, :liquor_license_number,:business_commenced, :date_occupied,\
     :credit_app_doc_id, :payment_method, :credit_limit, :approved_date,\
     :customer_id, :credit_application_version, :abn_checked, :director_signed,\
     :liquor_license_checked, :note, :id)
  end
