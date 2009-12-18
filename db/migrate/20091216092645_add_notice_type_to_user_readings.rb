class AddNoticeTypeToUserReadings < ActiveRecord::Migration
  def self.up
    add_column :user_readings, :notice_type, :string
    add_index :user_readings, :notice_type
    notice_entries_ids = BoardEntry.notice.map(&:id)
    UserReading.all.each do |ur|
      ur.update_attributes(:notice_type => 'notice') if notice_entries_ids.include?(ur.board_entry_id)
    end
  end

  def self.down
    remove_column :user_readings, :notice_type
  end
end
