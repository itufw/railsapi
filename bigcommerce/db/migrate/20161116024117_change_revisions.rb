class ChangeRevisions < ActiveRecord::Migration
  def change
  	#remove_column :revisions, :next_update_time
  	#remove_column :revisions, :notes
  	add_column :revisions, :last_update_time, :datetime

  end
end
