class AddDisplayCalendarToUserCustom < ActiveRecord::Migration
  def self.up
    add_column :user_customs, :display_calendar, :boolean, :default => true, :null => false
  end

  def self.down
    remove_column :user_customs, :display_calendar
  end
end
