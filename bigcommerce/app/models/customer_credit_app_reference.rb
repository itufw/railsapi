class CustomerCreditAppReference < ActiveRecord::Base
  belongs_to :customer
  belongs_to :customer_credit_app

  def credit_app_update(customer_credit_app_id, reference_params, customer_id)
    reference = CustomerCreditAppReference.existed?(customer_credit_app_id, reference_params[:contact_name], reference_params[:company_name])
    unless reference.nil?
      reference.update_attributes(reference_params)
      return reference
    end
    self.update_attributes(reference_params.merge({customer_credit_app_id: customer_credit_app_id, customer_id: customer_id}))
    self
  end

  def self.existed?(customer_credit_app_id, contact_name, company_name)
    where(customer_credit_app_id: customer_credit_app_id, contact_name: contact_name, company_name: company_name).first
  end
end
