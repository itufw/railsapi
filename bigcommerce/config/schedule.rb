# Use this file to easily define all of your cron jobs.
#
# It's helpful, but not entirely necessary to understand cron before proceeding.
# http://en.wikipedia.org/wiki/Cron

# Example:
#
# set :output, "/path/to/my/cron_log.log"
#
# every 2.hours do
#   command "/usr/bin/some_great_command"
#   runner "MyModel.some_method"
#   rake "some:great:rake:task"
# end
#
# every 4.days do
#   runner "AnotherModel.prune_old_records"
# end

# Learn more: http://github.com/javan/whenever
require "active_support/all"

Time.zone = "Melbourne"

set :environment, "production"

set :output, {:error => "log/cron_error_log.log", :standard => "log/cron_log.log"}

every 5.minutes do
	rake "updates:models"
end

every 1.day, :at => Time.zone.parse('6:00 pm').utc do
	rake "updates:balance_update"
end

every 1.day, :at => Time.zone.parse('6:00 pm').utc do
	rake "updates:timeperiods"
end

every 1.day, :at => Time.zone.parse('11:00 pm').utc do
  rake "xero_invoice_sync:sync"
end

every 1.day, :at => Time.zone.parse('1:00 am').utc do
  rake "xero_invoice_sync:sync"
end

every 1.day, :at => Time.zone.parse('6:30 am').utc do
  rake "xero_invoice_sync:sync"
end

every 1.day, :at => Time.zone.parse('8:00 am').utc do
  rake "xero_invoice_sync:sync"
end
