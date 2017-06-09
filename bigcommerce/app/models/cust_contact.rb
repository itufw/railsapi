class CustContact < ActiveRecord::Base
  belongs_to :contact
  belongs_to :customer

  def self.filter_by_customer(id)
    where('cust_contacts.customer_id = ?', id)
  end
end
