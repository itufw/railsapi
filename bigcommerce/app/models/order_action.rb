class OrderAction < ActiveRecord::Base
  belongs_to :order
  belongs_to :task

end
