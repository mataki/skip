class RenamePasswordResetTokenOnUsers < ActiveRecord::Migration
  def self.up
    rename_column :users, :password_reset_token, :reset_auth_token
    rename_column :users, :password_reset_token_expires_at, :reset_auth_token_expires_at
  end

  def self.down
    rename_column :users, :reset_auth_token, :password_reset_token
    rename_column :users, :reset_auth_token_expires_at, :password_reset_token_expires_at
  end
end
