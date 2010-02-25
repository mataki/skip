class RemovePublicationsFromBoardEntriesAndShareFiles < ActiveRecord::Migration
  def self.up
    remove_column :board_entries, :publication_symbols_value
    remove_column :share_files, :publication_symbols_value
    drop_table :entry_publications
    drop_table :share_file_publications
  end

  def self.down
    raise IrreversibleMigration
  end
end
