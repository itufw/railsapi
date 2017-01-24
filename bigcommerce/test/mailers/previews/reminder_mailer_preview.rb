# Preview all emails at http://localhost:3000/rails/mailers/reminder_mailer
class ReminderMailerPreview < ActionMailer::Preview
  def send_overdue_reminder
    ReminderMailer.send_overdue_reminder("2111","overdue")
  end

  def send_overdue(customer_id,template)
    ReminderMailer.send_overdue_reminder(customer_id,template)
  end
end
