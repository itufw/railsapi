require 'xero_connection.rb'
require 'clean_data.rb'

class XeroContact < ActiveRecord::Base

	include CleanData
    self.primary_key = 'xero_contact_id'

    belongs_to :customer
    has_many :xero_invoices
    has_many :xero_payments
    has_many :xero_credit_notes
    has_many :xero_overpayments
    has_many :xero_receipts

    def download_data_from_api(modified_since_time)
    	xero = XeroConnection.new.connect
        page_num = 1

    	contacts = xero.Contact.all(page: page_num, modified_since: modified_since_time)

        contacts.each do |c|
			insert_or_update_contact(c)
            page_num += 1
            contacts = xero.Contact.all(page: page_num, modified_since: modified_since_time)
		end
    end


    def insert_or_update_contact(c)

        contact_name = remove_apostrophe(c.name)
        firstname = remove_apostrophe(c.first_name)
        lastname = remove_apostrophe(c.last_name)
        email = remove_apostrophe(c.email_address)
        skype = remove_apostrophe(c.skype_user_name)
        updated_date = map_date(c.updated_date_utc)

        is_supplier = convert_bool(c.is_supplier)
        is_customer = convert_bool(c.is_customer)

        contact_groups = convert_empty_list(c.contact_groups)

        # if c.balances.nil?
        #     accounts_receivable_outstanding = 0.00
        #     accounts_receivable_overdue = 0.00
        # else
        #     accounts_receivable_outstanding = c.balances.accounts_receivable.outstanding
        #     accounts_receivable_overdue = c.balances.accounts_receivable.overdue
        # end

        time = Time.now.to_s(:db)

        if contact_doesnt_exist(c.contact_id)

            sql = "INSERT INTO xero_contacts (xero_contact_id, name, firstname, lastname,\
            email, skype_user_name, contact_number, contact_status, updated_date, account_number,\
            tax_number, bank_account_details, accounts_receivable_tax_type,\
            contact_groups, default_currency, purchases_default_account_code, sales_default_account_code,\
            is_supplier, is_customer, created_at, updated_at)\
            VALUES ('#{c.contact_id}', '#{contact_name}', '#{firstname}', '#{lastname}',\
            '#{email}', '#{skype}', '#{c.contact_number}', '#{c.contact_status}',\
            '#{updated_date}', '#{c.account_number}', '#{c.tax_number}', '#{c.bank_account_details}',\
            '#{c.accounts_receivable_tax_type}', '#{contact_groups}',\
            '#{c.default_currency}', '#{c.purchases_default_account_code}', '#{c.sales_default_account_code}',\
            '#{is_supplier}', '#{is_customer}', '#{time}', '#{time}')"

        else

            sql = "UPDATE xero_contacts SET name = '#{contact_name}', firstname = '#{firstname}',\
            lastname = '#{lastname}', email = '#{email}', skype_user_name = '#{skype}',\
            contact_number = '#{c.contact_number}', contact_status = '#{c.contact_status}',\
            updated_date = '#{updated_date}', account_number = '#{c.account_number}',\
            tax_number = '#{c.tax_number}', bank_account_details = '#{c.bank_account_details}',\
            accounts_receivable_tax_type = '#{c.accounts_receivable_tax_type}',\
            contact_groups = '#{contact_groups}',\
            default_currency = '#{c.default_currency}', purchases_default_account_code = '#{c.purchases_default_account_code}',\
            sales_default_account_code = '#{c.sales_default_account_code}', is_supplier = '#{is_supplier}',\
            is_customer = '#{is_customer}', updated_at = '#{time}'\
            WHERE xero_contact_id = '#{c.contact_id}'"

        end

        ActiveRecord::Base.connection.execute(sql)

    end

    def self.find_by_skype_id(skype_id)
    	return where(skype_user_name: skype_id).first
    end

    def self.get_accounts_receivable_outstanding(xero_contact)
        return xero_contact.accounts_receivable_outstanding if xero_contact

    end

    def self.get_accounts_receivable_overdue(xero_contact)
        return xero_contact.accounts_receivable_overdue if xero_contact
    end

    def self.create_in_xero(customer)
        c = customer
        xero = XeroConnection.new.connect
        contact = xero.Contact.build(name: c.actual_name || (c.firstname + ' ' + c.lastname),\
            first_name: c.firstname,\
            last_name: c.lastname, email_address: c.email, skype_user_name: c.id,\
            contact_number: c.phone, is_customer: true)
        contact.save
        return contact
    end

    def contact_doesnt_exist(contact_id)
        if XeroContact.where(xero_contact_id: contact_id).count == 0
            return true
        else
            return false
        end
    end

    def self.get_contact_from_xero(contact_id)
        xero = XeroConnection.new.connect
        contact = xero.Contact.find(contact_id)
        return contact
    end

end
