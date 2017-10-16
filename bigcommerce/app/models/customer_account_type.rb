class CustomerAccountType < ActiveRecord::Base

  def self.account_type
    where(status: 'account_type')
  end

  def self.account_status
    where(status: 'account_status')
  end

  def self.default_courier
    where(status: 'default_courier')
  end
end
