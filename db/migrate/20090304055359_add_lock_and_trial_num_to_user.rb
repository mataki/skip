class AddLockAndTrialNumToUser < ActiveRecord::Migration
  def self.up
    add_column :users, :lock, :boolean, :null => false, :default => false
    add_column :users, :trial_num, :integer, :null => false, :default => 0
  end

  def self.down
    remove_column :users, :lock
    remove_column :users, :trial_num
  end
end
