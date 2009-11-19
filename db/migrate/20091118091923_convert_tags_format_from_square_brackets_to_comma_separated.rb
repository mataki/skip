class ConvertTagsFormatFromSquareBracketsToCommaSeparated < ActiveRecord::Migration
  def self.up
    #chain_tagsは既にカンマ区切りになっている
    ActiveRecord::Base.transaction do
      #board_entry
      BoardEntry.record_timestamps = false
      BookmarkComment.record_timestamps = false
      ShareFile.record_timestamps = false
      BoardEntry.all.each do |entry|
        if entry.category.blank?
          puts "skipped :board_entry_id => #{entry.id} because category is blank."
        else
          entry.update_attributes! :category => comma_tags(entry.category)
          puts "update successful :entry_id => #{entry.id}"
        end
      end
      #bookmark_comment
      BookmarkComment.all.each do |comment|
        if comment.tags.blank?
          puts "skipped :bookmark_comment_id => #{comment.id} because tags is blank."
        else
          comment.update_attributes! :tags => comma_tags(comment.tags)
          puts "update successful :bookmark_comment_id => #{comment.id}"
        end
      end
      #share_file
      ShareFile.all.each do |file|
        if file.category.blank?
          puts "skipped :share_file_id => #{file.id} because tags is blank."
        else
          file.update_attributes! :category => comma_tags(file.category)
          puts "update successful :share_file_id => #{file.id}"
        end
      end
    end
  ensure
    BoardEntry.record_timestamps = true
    BookmarkComment.record_timestamps = true
    ShareFile.record_timestamps = true
  end

  def self.down
    raise IrreversibleMigration
  end

  class ::BoardEntry < ActiveRecord::Base
  end
  class ::ShareFile < ActiveRecord::Base
  end
  class ::BookmarkComment < ActiveRecord::Base
  end

  def self.comma_tags tags_as_string
    tags_as_string ? tags_as_string.gsub("][", ",").gsub("[", "").gsub("]", "") : ""
  end
end

