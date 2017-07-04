class CustContact < ActiveRecord::Base
  belongs_to :contact
  belongs_to :customer

  self.per_page = 30

  def self.filter_by_customer(id)
    where('cust_contacts.customer_id = ?', id)
  end

  def self.filter_by_contacts(ids)
    return all if ids.nil? || ids.empty?
    where('cust_contacts.contact_id IN (?)', ids)
  end

  def self.filter_by_staff(id)
    return all if id.nil?
    joins(:customer).where('customers.staff_id = ?', id)
  end

  def self.filter_by_contact_and_customer(customer_id, contact_id)
    where('customer_id = ? AND contact_id = ?', customer_id, contact_id)
  end

  def self.filter_by_role(role)
    return all if role.nil? || role == ""
    where('cust_contacts.position = ? ', role.to_s)
  end

  def self.search_for(search_text)
    where('cust_contacts.contact_id IN (?) OR cust_contacts.customer_id IN (?)', Contact.search_for(search_text).select('id'), Customer.search_for(search_text).select('id'))
  end

  def self.order_by_contacts(direction)
    order('cust_contacts.contact_id ' + direction)
  end
end
