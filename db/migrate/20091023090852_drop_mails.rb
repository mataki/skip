class DropMails < ActiveRecord::Migration
  def self.up
    drop_table :mails
  end

  def self.down
    create_table :mails do |t|
      t.string   "from_user_id",      :limit => 100,  :default => "",    :null => false
      t.integer  "user_entry_no",                                        :null => false
      t.string   "to_address",        :limit => 1000, :default => "",    :null => false
      t.boolean  "send_flag",                         :default => false, :null => false
      t.string   "title",             :limit => 100,  :default => "",    :null => false
      t.string   "to_address_name",   :limit => 200,  :default => "",    :null => false
      t.string   "to_address_symbol", :limit => 128,  :default => "",    :null => false
      t.timestamps
    end
    add_index :mails, :from_user_id
  end
end
