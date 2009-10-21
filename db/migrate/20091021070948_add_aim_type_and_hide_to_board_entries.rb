class AddAimTypeAndHideToBoardEntries < ActiveRecord::Migration
  def self.up
    add_column :board_entries, :aim_type, :string, :default => 'entry'
    add_column :board_entries, :hide, :boolean, :default => false

    add_index :board_entries, :aim_type
    add_index :board_entries, :hide
  end

  def self.down
    remove_column :board_entries, :aim_type
    remove_column :board_entries, :hide
  end
end
