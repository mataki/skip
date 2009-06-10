class AddDeletedAtToGroups < ActiveRecord::Migration
  def self.up
    add_column :groups, :deleted_at, :datetime
  end

  def self.down
    remove_column :groups, :deleted_at
  end
end
