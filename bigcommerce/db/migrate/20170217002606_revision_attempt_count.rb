class RevisionAttemptCount < ActiveRecord::Migration
  def change
    add_column :revisions, :attempt_count, :integer
  end
end
