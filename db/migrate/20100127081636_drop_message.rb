class DropMessage < ActiveRecord::Migration
  def self.up
    drop_table :messages
  end

  def self.down
    create_table "messages", :force => true do |t|
      t.datetime "created_on"
      t.integer  "user_id",                         :null => false
      t.string   "link_url",     :default => "",    :null => false
      t.string   "message",      :default => "",    :null => false
      t.string   "message_type", :default => "",    :null => false
      t.boolean  "send_flag",    :default => false, :null => false
    end
  end
end
