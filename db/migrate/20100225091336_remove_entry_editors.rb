class RemoveEntryEditors < ActiveRecord::Migration
  def self.up
    drop_table :entry_editors
  end

  def self.down
    raise IrreversibleMigration
  end
end
