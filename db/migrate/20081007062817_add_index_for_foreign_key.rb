class AddIndexForForeignKey < ActiveRecord::Migration
  def self.up
    add_index :antenna_items, :antenna_id
    add_index :antennas, :user_id
    add_index :applied_emails, :user_id
    add_index :board_entry_comments, :user_id
    add_index :bookmark_comments, :bookmark_id
    add_index :bookmark_comments, :user_id
    add_index :chains, :from_user_id
    add_index :chains, :to_user_id
    add_index :entry_accesses, :visitor_id
    add_index :entry_editors, :board_entry_id
    add_index :entry_trackbacks, :board_entry_id
    add_index :entry_trackbacks, :tb_entry_id
    add_index :group_participations, :user_id
    add_index :group_participations, :group_id
    add_index :mails, :from_user_id
    add_index :messages, :user_id
    add_index :share_file_accesses, :user_id
    add_index :share_file_publications, :share_file_id
    add_index :share_file_tags, :share_file_id
    add_index :share_file_tags, :tag_id
    add_index :share_files, :user_id
    add_index :tracks, :visitor_id
    add_index :user_accesses, :user_id
    add_index :user_customs, :user_id
    add_index :user_message_unsubscribes, :user_id
    add_index :user_profiles, :user_id
  end

  def self.down
    remove_index :antenna_items, :antenna_id
    remove_index :antennas, :user_id
    remove_index :applied_emails, :user_id
    remove_index :board_entry_comments, :user_id
    remove_index :bookmark_comments, :bookmark_id
    remove_index :bookmark_comments, :user_id
    remove_index :chains, :from_user_id
    remove_index :chains, :to_user_id
    remove_index :entry_accesses, :visitor_id
    remove_index :entry_editors, :board_entry_id
    remove_index :entry_trackbacks, :board_entry_id
    remove_index :entry_trackbacks, :tb_entry_id
    remove_index :group_participations, :user_id
    remove_index :group_participations, :group_id
    remove_index :mails, :from_user_id
    remove_index :messages, :user_id
    remove_index :share_file_accesses, :user_id
    remove_index :share_file_publications, :share_file_id
    remove_index :share_file_tags, :share_file_id
    remove_index :share_file_tags, :tag_id
    remove_index :share_files, :user_id
    remove_index :tracks, :visitor_id
    remove_index :user_accesses, :user_id
    remove_index :user_customs, :user_id
    remove_index :user_message_unsubscribes, :user_id
    remove_index :user_profiles, :user_id
  end
end

