class ChangeIndexOfBoardEntries < ActiveRecord::Migration
  def self.up
    remove_index :board_entries, :aim_type
    remove_index :board_entries, :hide
    add_index :board_entries, :last_updated
  end

  def self.down
    add_index :board_entries, :aim_type
    add_index :board_entries, :hide
    remove_index :board_entries, :last_updated
  end
end
