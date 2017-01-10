class ReminderMailer < ActionMailer::Base
  default from: 'it@untappedwines.com'
  layout "mailer"

  def reminder_email(customer)
    @customer = customer
    mail(to: 'it@untappedwines.com', subject: 'Testing from the cms')
  end
end
