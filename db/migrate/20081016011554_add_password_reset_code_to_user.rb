class AddPasswordResetCodeToUser < ActiveRecord::Migration
  def self.up
    add_column :users, :password_reset_token, :string
    add_column :users, :password_reset_token_expires_at, :datetime

    add_index :users, :password_reset_token
  end

  def self.down
    remove_column :users, :password_reset_token
    remove_column :users, :password_reset_token_expires_at
  end
end
