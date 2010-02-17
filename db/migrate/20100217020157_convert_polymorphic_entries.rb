class ConvertPolymorphicEntries < ActiveRecord::Migration
  def self.up
    add_column :board_entries, :owner_id, :integer, :null => false
    add_column :board_entries, :owner_type, :string, :null => false
    remove_column :board_entries, :symbol
  end

  def self.down
    raise IrreversibleMigration
  end
end
