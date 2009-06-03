class CreateUserOauthAccesses < ActiveRecord::Migration
  def self.up
    create_table :user_oauth_accesses do |t|
      t.string :app_name
      t.string :token
      t.string :secret
      t.integer :user_id
      t.timestamps
    end
    add_index :user_oauth_accesses, :user_id
    add_index :user_oauth_accesses, :app_name
  end

  def self.down
    drop_table :user_oauth_accesses
  end
end
