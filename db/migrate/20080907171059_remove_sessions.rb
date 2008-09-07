class RemoveSessions < ActiveRecord::Migration
  def self.up
    drop_table :sessions
  end

  def self.down
    create_table "sessions", :force => true do |t|
      t.string   "sid",          :limit => 100, :default => "", :null => false
      t.string   "user_code",    :limit => 20,  :default => "", :null => false
      t.string   "user_name",    :limit => 200, :default => "", :null => false
      t.string   "user_email",   :limit => 100, :default => "", :null => false
      t.datetime "expire_date",                                 :null => false
      t.string   "user_section", :limit => 200, :default => "", :null => false
    end
  end
end
