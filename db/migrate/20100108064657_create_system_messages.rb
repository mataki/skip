class CreateSystemMessages < ActiveRecord::Migration
  def self.up
    create_table :system_messages do |t|
      t.string   :message_type, :default => '',    :null => false
      t.string   :message_hash, :default => ''
      t.boolean  :send_flag,    :default => false, :null => false

      t.references :user
      t.timestamps
    end
    add_index :system_messages, :user_id
    add_index :system_messages, :message_type
  end

  def self.down
    drop_table :system_messages
  end
end
