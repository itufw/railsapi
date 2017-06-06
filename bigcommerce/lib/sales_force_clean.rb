module SalesForceClean
  def assign_phone_number_from_contact
    contact_roles = ContactRole.all
    contacts = Contact.sales_force
    contacts.each do |contact|
      # number, fax, mobile
      # numbers = contact.personal_number.split('/')

    end
  end
end
