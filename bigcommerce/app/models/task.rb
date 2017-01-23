class Task < ActiveRecord::Base
  has_many :task_activities
  has_many :task_relations

  def insert_or_update(t)
    time = Time.now.to_s(:db)

    task = "(#{t.start_date}, #{t.end_date}, #{time}, #{time}, '#{t.title}', '#{t.description}', #{t.is_task},\
            #{t.staff_id}, #{t.staff_id}, '#{t.method}', '#{t.categorise}')"

    # sql = "INSERT INTO `tasks`(`start_date`, `end_date`, `created_at`, `updated_at`,\
    #       `title`, `description`, `is_task`, `response_staff`, `last_modified_staff`, `method`,\
    #       `categorise`, `parent_task`, `subject_1`, `subject_2`, `subject_3`)\
    #       VALUES (#{t})"

    sql = "INSERT INTO `tasks`(`start_date`, `end_date`, `created_at`, `updated_at`,\
          `title`, `description`, `is_task`, `response_staff`, `last_modified_staff`, `method`,\
          `categorise`)\
          VALUES #{task}"
  end
end
