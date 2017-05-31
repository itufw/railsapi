class ProductNote < ActiveRecord::Base
  belongs_to :task
  belongs_to :creator, class_name: 'Staff', foreign_key: :created_by
  belongs_to :product

  def self.filter_task(task_id)
    where('product_notes.task_id = ?', task_id)
  end
end
