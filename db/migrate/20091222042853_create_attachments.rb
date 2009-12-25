class CreateAttachments < ActiveRecord::Migration
  def self.up
    create_table :attachments do |t|
      t.string :content_type, :null => false
      t.string :filename, :null => false
      t.string :display_name, :null => false
      t.integer :size, :null => false, :default => 0
      t.integer :user_id, :null => false
      t.integer :db_file_id
      t.integer :page_id

      t.timestamps
    end
  end

  def self.down
    drop_table :attachments
  end
end
