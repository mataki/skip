class RemoveDbFileIdFromAttachments < ActiveRecord::Migration
  def self.up
    remove_column :attachments, :db_file_id
  end

  def self.down
    add_column :attachments, :db_file_id, :integer
  end
end
