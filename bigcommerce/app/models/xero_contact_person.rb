require 'clean_data.rb'

class XeroContactPerson < ActiveRecord::Base
  include CleanData
  belongs_to :xero_contacts

  def insert_or_update_contact_people(people, contact_id, customer_id)
    people.each do |person|
      insert_or_update_contact_person(person, contact_id, customer_id)
    end
  end

  def insert_or_update_contact_person(person, contact_id, customer_id)
    is_include_in_mails = convert_bool(person.include_in_emails)
    time = Time.now.to_s(:db)

    unless contact_person_exists(person, contact_id)
      sql = "INSERT INTO xero_contact_people (xero_contact_id, customer_id, first_name, last_name,\
          email_address, include_in_emails, created_at, updated_at)\
          VALUES ('#{contact_id}', '#{customer_id}', \"#{person.first_name}\", \"#{person.last_name}\",\
          '#{person.email_address}', '#{is_include_in_mails}', '#{time}', '#{time}')"
    else
      sql = "UPDATE xero_contact_people SET email_address = '#{person.email_address}',\
      include_in_emails = '#{is_include_in_mails}', updated_at = '#{time}'\
      WHERE xero_contact_id = '#{contact_id}' and first_name = \"#{person.first_name}\" and last_name = \"#{person.last_name}\""
    end
    ActiveRecord::Base.connection.execute(sql)
  end

  def contact_person_exists(person, contact_id)
    return (XeroContactPerson.where("xero_contact_id = '#{contact_id}' and first_name = \"#{person.first_name}\" and last_name = \"#{person.last_name}\"").count > 0)
  end

  def self.all_contact_people(xero_contact_id)
    where("xero_contact_id = '#{xero_contact_id}'")
  end
end
