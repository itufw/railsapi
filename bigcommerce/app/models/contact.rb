require 'xero_connection.rb'

class Contact < ActiveRecord::Base
  belongs_to :xero_contact
  belongs_to :customer

  # DO NOT USE
  def download_data_from_api(modified_since_time)
    xero = XeroConnection.new.connect
    contacts = xero.Contact.all(modified_since: modified_since_time)
    contacts.each do |contact|
      insert_or_update_contacts(contact.phones, contact.skype_user_name, contact.id)
    end
  end

  def insert_or_update_contacts(contacts, customer_id, xero_contact_id)
    contacts.each do |contact|
        insert_or_update_contact(contact, customer_id, xero_contact_id) unless contact.country_code.nil?
    end
  end

  def insert_or_update_contact(contact, customer_id, xero_contact_id)
    exist_contact = contact_exist(contact, customer_id, xero_contact_id)
    unless exist_contact.count > 0
      new_contact = Contact.new
      new_contact.xero_contact_id = xero_contact_id
      new_contact.customer_id = customer_id
      new_contact.name = contact.country_code
      new_contact.number = contact.number
      new_contact.phone_type = contact.type
      new_contact.area_code = contact.area_code
      new_contact.save
    else
      update_contact = exist_contact.first
      update_contact.name = contact.country_code
      update_contact.number = contact.number
      update_contact.phone_type = contact.type
      update_contact.area_code = contact.area_code
      update_contact.save
    end
  end

  def contact_exist(contact, customer_id, xero_contact_id)
    return Contact.where("xero_contact_id = '#{xero_contact_id}' AND customer_id = '#{customer_id}' AND name ='#{contact.country_code}'")
  end

  def self.filter_by_xero_contact_id(xero_contact_id)
    where("contacts.xero_contact_id = '#{xero_contact_id}'")
  end

end
