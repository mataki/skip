class AddClassicStyleFlag < ActiveRecord::Migration
  def self.up
    add_column :user_customs, :classic, :boolean, :default => false
  end

  def self.down
    remove_column :user_customs, :admin
  end
end
