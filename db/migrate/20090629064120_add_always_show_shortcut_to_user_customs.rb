class AddAlwaysShowShortcutToUserCustoms < ActiveRecord::Migration
  def self.up
    add_column :user_customs, :always_show_shortcut, :boolean, :null => false, :default => false
  end

  def self.down
    remove_column :user_customs, :always_show_shortcut
  end
end
