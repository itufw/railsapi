# clean sales force data
module SalesForceClean
  def update_lead_address
    leads = CustomerLead.where('street IS NOT NULL AND latitude IS NULL')
    leads.each do |lead|
      address = lead.street.to_s + ' ' + lead.city.to_s + ' ' + lead.state.to_s\
        + lead.postalcode.to_s + ' ' + lead.country.to_s
      lead.address = address
      lead.save
    end
  end

  def update_customer_address
    customers = Customer.where('street IS NULL AND lat IS NULL')
    customers.each do |customer|
      address = customer.addresses.order('created_at DESC').first
      next if address.nil?
      customer.street = address.street_1.to_s + ' ' + address.street_2.to_s
      customer.city = address.city
      customer.state = address.state
      customer.postcode = address.postcode
      customer.country = address.country
      customer.address = customer.street.to_s + ' ' + customer.city.to_s\
                         + ' ' + customer.state.to_s + ' '\
                         + customer.postcode.to_s + ' ' + customer.country.to_s
      customer.save
    end

    customers = Customer.where('street IS NOT NULL AND lat IS NULL')
    customers.each do |customer|
      address = customer.street.to_s + ' ' + customer.city.to_s + ' '\
                + customer.state.to_s + ' ' + customer.postcode.to_s + ' '\
                + customer.country.to_s
      customer.address = address
      customer.save
    end
  end

  def assign_phone_number_from_contact
    cust_contact = CustContact.joins(:customer).select('state, cust_contacts.*')
    cust_contact.each do |relation|
      contact_person = relation.contact
      numbers = contact_numbers(contact_person.personal_number, relation.state)
      next if numbers.nil?
      relation.fax = numbers.second
      relation.email = numbers.last
      relation.phone, contact_person.personal_number = primary_number(numbers)

      contact_person.save
      relation.save
    end
  end

  def email_address_update_from_xero
    XeroContactPerson.all.each do |person|
      relation = CustContact.joins(:contact).select('cust_contacts.id, name, email').filter_by_customer(person.customer_id)
      next if relation.blank?
      p_name = (person.first_name + ' ' + person.last_name).strip.downcase
      relation.each do |contact|
        next unless contact.name.downcase == p_name
        contact.email = person.email_address
        contact.save
        break
      end
    end
  end

  def phone_number_update_from_xero
    Contact.xero_contact.each do |contact|
      # sales force contact
      sf_c = CustContact.joins(:contact).select('cust_contacts.id, name, personal_number, phone, area_code, number').where('cust_contacts.customer_id = ? AND contacts.name LIKE ? AND (cust_contacts.phone IS NULL OR cust_contacts.phone IN ("0",""))', contact.customer_id, '%'+contact.name+'%')
      next if sf_c.blank?
      sf_c = sf_c.first
      number = (contact.area_code.to_s + contact.number.to_s).gsub(/\D/, '')
      sf_c.phone = number
      sf_c.save
    end
  end

  private

  def contact_numbers(personal_number, state)
    return nil if personal_number.nil?
    numbers = personal_number.gsub(%r{\/}, '/ ').split('/')
    return nil if numbers.length < 4
    numbers = numbers.map { |x| number_map(x, state) }
    numbers
  end

  # phone number filter
  def number_map(number, state)
    return number.strip if number.include?'@'

    number = number.gsub(/\D/, '')
    return nil if number.eql? ''
    number = '0' + number if number.first != '0' && number.length == 9
    number = get_area_code(state) + number if number.length == 8
    number
  end

  def get_area_code(state)
    return '02' if %w[NSW ACT].include?state
    return '03' if %w[VIC TAS].include?state
    return '07' if %w[QLD].include?state
    return '08' if %w[WA SA NT].include?state
    '04'
  end

  def primary_number(numbers)
    primary = numbers.first
    personal = numbers.third
    return personal, primary if primary.nil?
    return primary, personal if personal.nil?
    return primary, personal if personal.starts_with?'04'
    [personal, primary]
  end
end
