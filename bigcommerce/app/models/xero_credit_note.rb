require 'xero_connection.rb'
require 'clean_data.rb'

class XeroCreditNote < ActiveRecord::Base

	include CleanData
	self.primary_key = 'xero_credit_note_id'

	has_many :xero_cn_allocations
	has_many :xero_cn_line_items
	belongs_to :xero_contact

	def scrape

		xero = XeroConnection.new.connect

		all_credit_notes = xero.CreditNote.all

		all_credit_notes.each do |c|
			date = map_date(c.date)
			updated_date = map_date(c.updated_date_utc)
			fully_paid_on_date = map_date(c.fully_paid_on_date)
			contact_name = remove_apostrophe(c.contact_name)

			time = Time.now.to_s(:db)

			sql = "INSERT INTO xero_credit_notes (xero_credit_note_id, credit_note_number,\
			xero_contact_id, contact_name, status, line_amount_type, type, sub_total,\
			total, total_tax, remaining_credit, date, updated_date, fully_paid_on_date,\
			created_at, updated_at, currency_code, currency_rate, reference\
			VALUES ('#{c.credit_note_id}', '#{c.credit_note_number}',\
			'#{c.contact_id}', '#{contact_name}', '#{c.status}', '#{c.line_amount_types}',\
			'#{c.type}', '#{c.sub_total}', '#{c.total}', '#{c.total_tax}', '#{c.remaining_credit}',\
			'#{date}', '#{updated_date}', '#{fully_paid_on_date}', '#{time}', '#{time}',\
			'#{c.currency_code}', '#{c.currency_rate}', '#{c.reference}')"
			ActiveRecord::Base.connection.execute(sql)
			XeroCnAllocation.new.scrape(c.allocations, c.credit_note_id)
		end
	end

	def download_data_from_api(modified_since_time)
		xero = XeroConnection.new.connect
		credit_note = xero.CreditNote.all(modified_since: modified_since_time)
		credit_note.each do |c|
			insert_or_update_credit_note(c)
			XeroCNLineItem.new.download_line_items_from_api(xero, c)
		end
	end

	def insert_or_update_credit_note(c)

		date = map_date(c.date)
		updated_date = map_date(c.updated_date_utc)
		fully_paid_on_date = map_date(c.fully_paid_on_date)
		contact_name = remove_apostrophe(c.contact_name)

		time = Time.now.to_s(:db)

		if credit_note_doesnt_exist(c.credit_note_id)
			sql = "INSERT INTO xero_credit_notes (xero_credit_note_id, credit_note_number,\
			xero_contact_id, contact_name, status, line_amount_type, note, sub_total,\
			total, total_tax, remaining_credit, date, updated_date, fully_paid_on_date,\
			created_at, updated_at, currency_code, currency_rate, reference)\
			VALUES ('#{c.credit_note_id}', '#{c.credit_note_number}',\
			'#{c.contact_id}', '#{contact_name}', '#{c.status}', '#{c.line_amount_types}',\
			'#{c.type}', '#{c.sub_total}', '#{c.total}', '#{c.total_tax}', '#{c.remaining_credit}',\
			'#{date}', '#{updated_date}', '#{fully_paid_on_date}', '#{time}', '#{time}',\
			'#{c.currency_code}', '#{c.currency_rate}', \"#{c.reference}\")"
		else
			sql = "UPDATE xero_credit_notes SET credit_note_number = '#{c.credit_note_number}',\
			xero_contact_id = '#{c.contact_id}',contact_name = '#{contact_name}', status = '#{c.status}',\
			line_amount_type = '#{c.line_amount_types}',note = '#{c.type}', sub_total = '#{c.sub_total}',\
			total = '#{c.total}', total_tax = '#{c.total_tax}',remaining_credit = '#{c.remaining_credit}',\
			date = '#{date}', updated_date = '#{updated_date}',fully_paid_on_date = '#{fully_paid_on_date}',\
			updated_at = '#{time}', currency_code = '#{c.currency_code}',currency_rate = '#{c.currency_rate}',\
			reference = \"#{c.reference}\"\
			WHERE xero_credit_note_id = '#{c.credit_note_id}'"
		end
		XeroCnAllocation.new.insert_cn_allocation(c.allocations,c.credit_note_id, c.credit_note_number, "allocations") unless c.allocations.nil?



		ActiveRecord::Base.connection.execute(sql)
	end

	def credit_note_doesnt_exist(credit_note_id)
			if XeroCreditNote.where(xero_credit_note_id: credit_note_id).count == 0
					return true
			else
					return false
			end
	end

	def self.get_remaining_credit(credit_note_id)
		where(" xero_credit_notes.status in ( 'AUTHORISED', 'PAID' ) and xero_contact_id = '#{credit_note_id}'")
	end

	def self.sum_remaining_credit
		sum('remaining_credit')
	end

end
