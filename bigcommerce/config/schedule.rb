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

# Cron syntax:
# ============
#
# * * * * * *
# | | | | | |
# | | | | | +-- Year              (range: 1900-3000)
# | | | | +---- Day of the Week   (range: 1-7, 1 standing for Monday)
# | | | +------ Month of the Year (range: 1-12)
# | | +-------- Day of the Month  (range: 1-31)
# | +---------- Hour              (range: 0-23, 1 in our example)
# +------------ Minute            (range: 0-59, 10 in our example)

require "active_support/all"

Time.zone = "Melbourne"

set :environment, "production"

set :output, {:error => "log/cron_error_log.log", :standard => "log/cron_log.log"}

# Big Commerce Updated
every 5.minutes do
	rake "updates:models"
end

# Google Calendar / Events Updated
every 1.hours do
	rake "updates:event_update"
end

# Fastway Tracking Information Updated
every '30 9-19,0 * * *' do
	rake 'updates:package_trace'
end

# Send Stock Control Email to the team
every '0 8 * * 1' do
	rake 'updates:send_stock_control'
end

# Email sale reports to the team on every Sunday's midnight
every '12 23 * * 7' do
	rake 'updates:send_sale_report'
end

# Refresh the Signature Pictures of Fastway
every 1.day, :at => '10:45 pm' do
	rake 'updates:wake_signatures'
end

# Update Customers Balance
every 1.day, :at => '9:00 am' do
	rake "updates:balanceupdate"

	rake "updates:timeperiods"
end

# Update Xero
every 1.day, :at => '11:45 am' do
  rake "xero_invoice_sync:sync"
end

# Fastway Manifest Updated
every 1.day, :at => '4:00 pm' do
	rake 'updates:manifest_update'
end

# Zomato Updated
every 1.day, :at => '7:00 pm' do
  rake "xero_invoice_sync:sync"

	rake "updates:zomato_update"

	rake 'updates:manifest_update'

	rake "updates:sales_rate_update"
end
