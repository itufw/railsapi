require 'xero_connection.rb'
require 'clean_data.rb'

class XeroContact < ActiveRecord::Base

	include CleanData
    self.primary_key = 'xero_contact_id'

    has_many :xero_invoices
    has_many :xero_payments
    has_many :xero_credit_notes
    has_many :xero_overpayments
    has_many :xero_receipts

    def scrape
    	xero = XeroConnection.new.connect

    	contacts = xero.Contact.all

        contacts.each do |c|

			contact_name = remove_apostrophe(c.name)
			firstname = remove_apostrophe(c.first_name)
			lastname = remove_apostrophe(c.last_name)
			email = remove_apostrophe(c.email_address)
			skype = remove_apostrophe(c.skype_user_name)
			updated_date = map_date(c.updated_date_utc)

            is_supplier = convert_bool(c.is_supplier)
            is_customer = convert_bool(c.is_customer)

            contact_groups = convert_empty_list(c.contact_groups)

            if c.balances.nil?
                accounts_receivable_outstanding = 0.00
                accounts_receivable_overdue = 0.00
            else
                accounts_receivable_outstanding = c.balances.accounts_receivable.outstanding
                accounts_receivable_overdue = c.balances.accounts_receivable.overdue
            end

			time = Time.now.to_s(:db)

			sql = "INSERT INTO xero_contacts (xero_contact_id, name, firstname, lastname,\
			email, skype_user_name, contact_number, contact_status, updated_date, account_number,\
			tax_number, bank_account_details, accounts_receivable_tax_type, accounts_payable_tax_type,\
			contact_groups, default_currency, purchases_default_account_code, sales_default_account_code,\
			is_supplier, is_customer, created_at, updated_at, accounts_receivable_outstanding,\
            accounts_receivable_overdue, accounts_payable_outstanding, accounts_payable_overdue)\
	  		VALUES ('#{c.contact_id}', '#{contact_name}', '#{firstname}', '#{lastname}',\
	  		'#{email}', '#{skype}', '#{c.contact_number}', '#{c.contact_status}',\
	  		'#{updated_date}', '#{c.account_number}', '#{c.tax_number}', '#{c.bank_account_details}',\
	  		'#{c.accounts_receivable_tax_type}', '#{c.accounts_payable_tax_type}', '#{contact_groups}',\
	  		'#{c.default_currency}', '#{c.purchases_default_account_code}', '#{c.sales_default_account_code}',\
	  		'#{is_supplier}', '#{is_customer}', '#{time}', '#{time}', '#{accounts_receivable_outstanding}',\
            '#{accounts_receivable_overdue}', '#{accounts_payable_outstanding}', '#{accounts_payable_overdue}')"

	  		ActiveRecord::Base.connection.execute(sql)
		end
    end

    def self.find_by_skype_id(skype_id)
    	return where(skype_user_name: skype_id).first
    end

    def self.get_accounts_receivable_outstanding(xero_contact_id)
        return find(xero_contact_id).accounts_receivable_outstanding if xero_contact_id

    end

    def self.get_accounts_receivable_overdue(xero_contact_id)
        return find(xero_contact_id).accounts_receivable_overdue if xero_contact_id
    end

end
