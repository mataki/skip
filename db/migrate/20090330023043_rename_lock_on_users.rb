class RenameLockOnUsers < ActiveRecord::Migration
  def self.up
    rename_column :users, :lock, :locked
  end

  def self.down
    rename_column :users, :locked, :lock
  end
end
