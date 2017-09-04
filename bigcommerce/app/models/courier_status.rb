class CourierStatus < ActiveRecord::Base
  has_many :orders
end
