class OrderAction < ActiveRecord::Base
  belongs_to :order
  belongs_to :task

  def order_paid(order_id)
    order_action = OrderAction.new
    order_action.order_id = order_id
    order_action.action = "pay"
    order_action.save!

    Task.order_tasks(order_id).active_tasks.each do |task|
      task.expired = 1
      task.save!
    end
  end
end
