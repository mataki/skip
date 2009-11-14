class CreateNotices < ActiveRecord::Migration
  def self.up
    create_table :notices do |t|
      t.references :user, :null => false
      t.integer :target_id, :null => false
      t.string :target_type, :null => false
      t.timestamps
    end

    add_index :notices, :user_id
    add_index :notices, :target_id
  end

  def self.down
    drop_table :notices
  end
end

