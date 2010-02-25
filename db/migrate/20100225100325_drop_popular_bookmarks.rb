class DropPopularBookmarks < ActiveRecord::Migration
  def self.up
    drop_table :popular_bookmarks
  end

  def self.down
    raise IrreversibleMigration
  end
end
