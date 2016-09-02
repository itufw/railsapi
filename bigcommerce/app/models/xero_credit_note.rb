require 'xero_connection.rb'
require 'clean_data.rb'

class XeroCreditNote < ActiveRecord::Base
	self.primary_key = 'xero_credit_note_id'

	has_many :xero_credit_note_allocations
	belongs_to :xero_contact

	def scrape

		xero = XeroConnection.new.connect
		clean = CleanData.new

		all_credit_notes = xero.CreditNote.all

		all_credit_notes.each do |c|

			date = clean.map_date(c.date.to_s)
			updated_date = clean.map_date(c.updated_date_utc.to_s)
			fully_paid_on_date = clean.map_date(c.fully_paid_on_date.to_s)

			contact_name = clean.remove_apostrophe(c.contact_name) unless c.contact_name.nil?


			time = Time.now.to_s(:db)

			sql = "INSERT INTO xero_credit_notes (xero_credit_note_id, credit_note_number,\
			xero_contact_id, xero_contact_name, status, line_amount_type, type, sub_total,\
			total, total_tax, remaining_credit, date, date_modified, fully_paid_on_date,\
			created_at, updated_at) VALUES ('#{c.credit_note_id}', '#{c.credit_note_number}',\
			'#{c.contact_id}', '#{contact_name}', '#{c.status}', '#{c.line_amount_types}',\
			'#{c.type}', '#{c.sub_total}', '#{c.total}', '#{c.total_tax}', '#{c.remaining_credit}',\
			'#{date}', '#{updated_date}', '#{fully_paid_on_date}', '#{time}', '#{time}')"


			ActiveRecord::Base.connection.execute(sql)

			XeroCreditNoteAllocation.new.scrape(c.allocations, c.credit_note_id)
		end

	end
end
