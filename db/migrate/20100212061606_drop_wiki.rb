class DropWiki < ActiveRecord::Migration
  def self.up
    drop_table :chapters
    drop_table :contents
    drop_table :histories
    drop_table :attachments
    drop_table :pages
    drop_table :db_files
  end

  def self.down
    raise IrreversibleMigration
  end
end
