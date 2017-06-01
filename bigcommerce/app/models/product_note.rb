class ProductNote < ActiveRecord::Base
  belongs_to :task
  belongs_to :creator, class_name: 'Staff', foreign_key: :created_by
  belongs_to :product

  def self.filter_task(task_id)
    where('product_notes.task_id = ?', task_id)
  end

  def self.filter_ids(ids)
    where('product_notes.id IN ()', ids)
  end
end
