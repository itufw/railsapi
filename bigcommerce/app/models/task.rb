class Task < ActiveRecord::Base
  has_many :task_activities
  has_many :task_relations

  def insert_or_update(t,start_date,end_date)
    time = Time.now.to_s(:db)

    task = "(#{t.id},'#{start_date}', '#{end_date}', '#{time}', '#{time}', '#{t.title}', '#{t.description}', #{t.is_task},\
            #{t.response_staff}, #{t.last_modified_staff}, '#{t.method}', '#{t.function}','#{t.subject_1}')"

    # sql = "INSERT INTO `tasks`(`start_date`, `end_date`, `created_at`, `updated_at`,\
    #       `title`, `description`, `is_task`, `response_staff`, `last_modified_staff`, `method`,\
    #       `categorise`, `parent_task`, `subject_1`, `subject_2`, `subject_3`)\
    #       VALUES (#{t})"

    sql = "INSERT INTO `tasks`(`id`,`start_date`, `end_date`, `created_at`, `updated_at`,\
          `title`, `description`, `is_task`, `response_staff`, `last_modified_staff`, `method`,\
          `function`, `subject_1`)\
          VALUES #{task}"

    ActiveRecord::Base.connection.execute(sql)
  end


  def insert_or_update_note(t,start_date)
    time = Time.now.to_s(:db)

    task = "(#{t.id},'#{start_date}', '#{start_date}', '#{time}', '#{time}', '#{t.description}', #{t.is_task},\
            #{t.response_staff}, #{t.last_modified_staff}, '#{t.function}', '#{t.subject_1}')"

    # sql = "INSERT INTO `tasks`(`start_date`, `end_date`, `created_at`, `updated_at`,\
    #       `title`, `description`, `is_task`, `response_staff`, `last_modified_staff`, `method`,\
    #       `categorise`, `parent_task`, `subject_1`, `subject_2`, `subject_3`)\
    #       VALUES (#{t})"

    sql = "INSERT INTO `tasks`(`id`,`start_date`,`end_date`, `created_at`, `updated_at`,\
          `description`, `is_task`, `response_staff`, `last_modified_staff`,\
          `function`, `subject_1`)\
          VALUES #{task}"

    ActiveRecord::Base.connection.execute(sql)
  end
end
