class RemoveDisplayCalendarFromUserCustoms < ActiveRecord::Migration
  def self.up
    remove_column :user_customs, :display_calendar
  end

  def self.down
    add_column :user_customs, :display_calendar, :boolean, :default => false, :null => false
  end
end
