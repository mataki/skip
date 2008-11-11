class RemoveCustomUsersFromSiteCounts < ActiveRecord::Migration
  def self.up
    remove_column :site_counts, :custom_users
  end

  def self.down
    add_column :site_counts, :custom_users, :integer, :null => false
  end
end
