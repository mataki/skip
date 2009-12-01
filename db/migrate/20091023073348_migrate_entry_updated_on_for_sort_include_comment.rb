class MigrateEntryUpdatedOnForSortIncludeComment < ActiveRecord::Migration
  def self.up
    BoardEntry.record_timestamps = false
    BoardEntry.all.each do |entry|
      if last_comment = entry.board_entry_comments.order_new.first
        if entry.updated_on < last_comment.updated_on
          entry.updated_on = last_comment.updated_on
          entry.save
          puts "updated entry:#{entry.id}"
        else
          puts "skipped entry:#{entry.id}"
        end
      else
        puts "skipped entry:#{entry.id}"
      end
    end
  ensure
    BoardEntry.record_timestamps = true
  end

  def self.down
    raise IrreversibleMigration
  end

  class ::BoardEntry < ActiveRecord::Base
    has_many :board_entry_comments, :dependent => :destroy
  end
end
