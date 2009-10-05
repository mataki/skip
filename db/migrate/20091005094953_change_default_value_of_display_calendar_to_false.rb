class ChangeDefaultValueOfDisplayCalendarToFalse < ActiveRecord::Migration
  def self.up
    change_column :user_customs, :display_calendar, :boolean, :default => false, :null => false
  end

  def self.down
    change_column :user_customs, :display_calendar, :boolean, :default => true, :null => false
  end
end
