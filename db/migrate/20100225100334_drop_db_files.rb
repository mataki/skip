class DropDbFiles < ActiveRecord::Migration
  def self.up
    drop_table :db_files
  end

  def self.down
    raise IrreversibleMigration
  end
end
