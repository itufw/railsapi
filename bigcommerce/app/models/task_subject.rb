class TaskSubject < ActiveRecord::Base
  belongs_to :task

  def self.distinct_function
    select(:function).distinct
  end

  def self.distinct_function_user(user_type)
    select(:function).distinct.where(:user_type => user_type)
  end

  def self.get_subjects_on_function(function)
    where(:function => function)
  end

  def self.get_subjects_on_user_type(user_type)
    if user_type.in?(["Management","Admin"])
      all
    else
      where(:user_type => user_type)
    end
  end

  def self.get_subjects
    select(:subject).distinct
  end
end
