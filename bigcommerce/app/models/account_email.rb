class AccountEmail < ActiveRecord::Base
  def record(email_content)
			time = Time.now.to_s(:db)
			email = "(\"#{email_content.receive_address}\",'#{email_content.email_type}',\"#{email_content.cc}\",\
      \"#{email_content.bcc}\",\"#{email_content.content}\",\"#{email_content.content_second}\",\
			\"#{email_content.customer_id}\",\"#{email_content.selected_invoices}\",'#{time}', '#{time}')"

			sql = "INSERT INTO account_emails (receive_address, email_type, cc, bcc,\
			content, content_second, customer_id, selected_invoices, created_at, updated_at)\
			VALUES #{email}"

			ActiveRecord::Base.connection.execute(sql)
	end
end
