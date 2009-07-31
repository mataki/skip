class AddDisplayEntriesFormatToUserCustom < ActiveRecord::Migration
  def self.up
    add_column :user_customs, :display_entries_format, :string, :default => "tabs", :null => false
  end

  def self.down
    remove_column :user_customs, :display_entries_format
  end
end
