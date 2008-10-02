class AddAuthSessionTokenToUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :auth_session_token, :string

    add_index :users, :auth_session_token
  end

  def self.down
    remove_column :users, :auth_session_token
  end
end
