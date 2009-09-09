class ChangeDisplayEntriesFormatDefaultToUserCustom < ActiveRecord::Migration
  def self.up
    change_column :user_customs, :display_entries_format, :string, :default => 'flat', :null => false
  end

  def self.down
    change_column :user_customs, :display_entries_format, :string, :default => 'tabs', :null => false
  end
end
