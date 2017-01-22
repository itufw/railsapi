class Task < ActiveRecord::Base
  has_many :task_activities
  has_many :task_relations

  def insert_or_update(task)
    t = ""
    sql = "INSERT INTO `tasks`(`id`, `start_date`, `end_date`, `created_at`, `updated_at`,\
          `title`, `description`, `is_task`, `response_staff`, `last_modified_staff`, `method`,\
          `categorise`, `parent_task`, `completed_date`, `completed_staff`, `subject_1`, `subject_2`,\
          `subject_3`)\
          VALUES #{t}"
  end
end
