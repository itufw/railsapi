class Note < ActiveRecord::Base
  belongs_to :customers
  belongs_to :staffs

  def self.valid
    where('due_date <= CURDATE()')
  end

end
