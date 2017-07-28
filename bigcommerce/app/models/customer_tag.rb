class CustomerTag < ActiveRecord::Base

  def insert_customer(customer)
    return nil if (CustomerTag.exist?('Customer', customer.id).count > 0)
    self.name = customer.actual_name
    self.role = 'Customer'
    self.customer_id = customer.id
    self.staff_nickname = customer.staff.nickname
    self.address = customer.address
    self.state = customer.state
    save
  end

  def insert_lead(lead)
    return nil if (CustomerTag.exist?('Lead', lead.id).count > 0)
    self.name = lead.actual_name.to_s + ', (Lead)'
    self.role = 'Lead'
    self.customer_id = lead.id
    self.staff_nickname = lead.staff.nickname
    self.address = lead.address
    self.state = lead.state
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

  def self.no_contacts
    where('role != "Contact"')
  end

  def update_record(role, customer_id, name)
    self.role = role
    self.customer_id = customer_id
    self.name = name
    self.save
    update_details
  end

  def update_details
    case self.role
    when 'Customer'
      customer = Customer.find(self.customer_id)
    when 'Lead'
      customer = CustomerLead.find(self.customer_id)
    else
      return
    end
    self.staff_nickname = customer.staff.nickname
    self.address = customer.address
    self.state = customer.state
    self.save
  end

  def details
    query = self.name
    query += ' | ' + self.staff_nickname.to_s unless self.staff_nickname.nil? || self.staff_nickname == ''
    query += ' | ' + self.state.to_s unless self.state.nil? || self.state == ''
    query
  end

  def staff_change(staff_nickname)
    self.staff_nickname = staff_nickname
    self.save
  end
end
