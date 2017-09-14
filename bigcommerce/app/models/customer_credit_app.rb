class CustomerCreditApp < ActiveRecord::Base
  belongs_to :customer
  has_many :customer_credit_app_references
  has_many :customer_credit_app_signeds
  mount_uploader :credit_app_doc_id, CreditAppUploader

end
