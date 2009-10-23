class DeleteAlwaysShowShortcutFromUserCustoms < ActiveRecord::Migration
  def self.up
    remove_column :user_customs, :always_show_shortcut
  end

  def self.down
    add_column :user_customs, :always_show_shortcut, :boolean, :null => false, :default => false
  end
end
