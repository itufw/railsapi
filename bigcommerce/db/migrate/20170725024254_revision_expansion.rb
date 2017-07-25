class RevisionExpansion < ActiveRecord::Migration
  def change
    add_column :revisions, :description, :string
  end
end
