class AddRememberTokenAndRememberTokenExpiresAtToUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :remember_token, :string
    add_column :users, :remember_token_expires_at, :datetime

    add_index :users, :remember_token
  end

  def self.down
    remove_column :users, :remember_token
    remove_column :users, :remember_token_expires_at
  end
end
