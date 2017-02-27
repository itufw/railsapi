require 'xero_connection.rb'
require 'clean_data.rb'

class XeroContact < ActiveRecord::Base
    include CleanData
    self.primary_key = 'xero_contact_id'

    has_one :customer
    has_many :xero_invoices
    has_many :xero_payments
    has_many :xero_credit_notes
    has_many :xero_overpayments
    has_many :xero_receipts
    has_many :xero_contact_people

    scoped_search on: [:name, :firstname, :lastname, :email, :skype_user_name]
    self.per_page = 100

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
        XeroContactPerson.new.insert_or_update_contact_people(c.contact_people, c.contact_id, skype) unless c.contact_people.nil?
    end

    # run the balance updating for all contacts whose contact id is not null
    def update_balance_for_all
        contacts = XeroContact.all
        contacts.each do |c|
            c.update_balance_from_tables(c.xero_contact_id) unless c.xero_contact_id.nil?
        end
      end

    # update balance for single contact
    def update_balance_from_tables(xero_contact_id)
        contacts = XeroContact.filter_by_id(xero_contact_id)
        # Outstanding =  amount_due - remaining_credit(CreditNote+Overpayment)
        # Overdue = c(due_date > ) - a -e

        time = Time.now.to_s(:db)
        amount_due = contacts.sum_invoice_amount_due || 0
        credit_note_remaining_credit = XeroCreditNote.get_remaining_credit(xero_contact_id).sum_remaining_credit || 0
        overpayment_remaining_credit = XeroOverpayment.get_remaining_credit(xero_contact_id).sum_remaining_credit || 0

        outstanding = amount_due - (credit_note_remaining_credit + overpayment_remaining_credit)
        overdue = contacts.filter_overdue_invoices(Date.today).sum_invoice_amount_due || 0

        sql = "UPDATE xero_contacts SET accounts_receivable_outstanding = '#{outstanding}',\
  			accounts_receivable_overdue = '#{overdue}', updated_at = '#{time}'\
  			WHERE xero_contact_id = '#{xero_contact_id}'"
        ActiveRecord::Base.connection.execute(sql)
      end

    def self.find_by_skype_id(skype_id)
        where(skype_user_name: skype_id).first
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
        contact
    end

    def contact_doesnt_exist(contact_id)
        if XeroContact.where(xero_contact_id: contact_id).count == 0
            true
        else
            false
        end
    end

    def self.get_contact_from_xero(contact_id)
        xero = XeroConnection.new.connect
        contact = xero.Contact.find(contact_id)
        contact
    end

    def self.update_balances_from_xero(contact_id)
        contact = XeroContact.get_contact_from_xero(contact_id)
        time = Time.now.to_s(:db)

        unless contact.balances.nil?
            accounts_receivable_outstanding = contact.balances.accounts_receivable.outstanding
            accounts_receivable_overdue = contact.balances.accounts_receivable.overdue

            sql = "UPDATE xero_contacts SET accounts_receivable_outstanding = '#{accounts_receivable_outstanding}',\
    				accounts_receivable_overdue = '#{accounts_receivable_overdue}', updated_at = '#{time}'\
    				WHERE xero_contact_id = '#{contact_id}'"
            ActiveRecord::Base.connection.execute(sql)
        end
      end

    def self.period_select(until_date)
        where('xero_contacts.xero_contact_id IN (?)', XeroInvoice.select(:xero_contact_id).period_select(until_date).uniq)
      end

    def self.sum_invoice_amount_due
        includes(:xero_invoices).sum('xero_invoices.amount_due')
      end

    def self.filter_overdue_invoices(time)
        includes(:xero_invoices).where("xero_invoices.due_date < '#{time}'")
      end

    def self.search_filter(search_text = nil)
        return search_for(search_text) if search_text
        all
      end

    def self.include_all
        includes(:customer, :xero_invoices, :xero_credit_notes, :xero_overpayments)
      end

    def self.outstanding_is_greater_zero
        where('xero_contacts.accounts_receivable_outstanding > 0')
      end

    def self.is_customer
      where("xero_contacts.skype_user_name REGEXP '^-?[0-9]+$'")
    end

    def self.order_by_name(direction)
        order('name ' + direction)
      end

    def self.order_by_outstanding(direction)
        order('xero_contacts.accounts_receivable_outstanding ' + direction)
      end

    def self.order_by_overdue(direction)
        order('xero_contacts.accounts_receivable_overdue ' + direction)
      end

    def self.order_by_invoice(direction, start_date, end_date, date_column)
      date_column = (date_column.eql? "invoice_date") ? 'date' : 'due_date'
      joins("RIGHT JOIN xero_invoices ON xero_contacts.xero_contact_id = xero_invoices.xero_contact_id").\
      where("xero_invoices.#{date_column} > '#{start_date}' and xero_invoices.#{date_column} <= '#{end_date}'").\
      group('xero_invoices.xero_contact_id').\
      order(" SUM(xero_invoices.amount_due) " + direction)
    end

    def self.filter_by_id(contact_id)
        where("xero_contacts.xero_contact_id = '#{contact_id}' ")
      end

end
