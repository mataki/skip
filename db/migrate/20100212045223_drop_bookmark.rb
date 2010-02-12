class DropBookmark < ActiveRecord::Migration
  def self.up
    drop_table :bookmarks
    drop_table :bookmark_comments
    drop_table :bookmark_comment_tags
  end

  def self.down
    raise IrreversibleMigration
  end
end
