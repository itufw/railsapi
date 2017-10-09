class CustomerCreditAppSigned < ActiveRecord::Base
  belongs_to :customer
  belongs_to :contact
  belongs_to :customer_credit_app

  def credit_app_update(credit_app_id, contact_id, customer_id, user_id, active)
    signed = CustomerCreditAppSigned.existed?(credit_app_id, contact_id, customer_id)
    unless signed.nil?
      signed.update_attributes({assigned_staff: user_id,\
        active: active, updated_at: Time.now.to_s(:db)})
      return signed
    end
    self.update_attributes({customer_credit_app_id: credit_app_id,\
      contact_id: contact_id, customer_id: customer_id, assigned_staff: user_id,\
      active: active, created_at: Time.now.to_s(:db), updated_at: Time.now.to_s(:db)})
    self
  end

  def self.existed?(credit_app_id, contact_id, customer_id)
    where(customer_credit_app_id: credit_app_id, contact_id: contact_id, customer_id: customer_id).first
  end
end
