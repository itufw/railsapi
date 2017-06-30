class CustomerTag < ActiveRecord::Base

  def insert_customer(customer)
    return nil if (CustomerTag.exist?('Customer', customer.id).count > 0)
    self.name = customer.actual_name
    self.role = 'Customer'
    self.customer_id = customer.id
    save
  end

  def insert_lead(lead)
    return nil if (CustomerTag.exist?('Lead', lead.id).count > 0)
    self.name = lead.actual_name.to_s + ', (Lead)'
    self.role = 'Lead'
    self.customer_id = lead.id
    save
  end

  def insert_contact(contact)
    return nil if (CustomerTag.exist?('Contact', contact.id).count > 0)
    self.name = contact.name.to_s + ', (Contact)'
    self.role = 'Contact'
    self.customer_id = contact.id
    save
  end

  def self.exist?(role, id)
    where('role = ? AND customer_id = ?', role, id)
  end

  def self.filter_by_role(role)
    where('role = ?', role)
  end
end
