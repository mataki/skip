class AddIssuedAtAndPasswordExpiresAtToUser < ActiveRecord::Migration
  def self.up
    add_column :users, :issued_at, :datetime
    add_column :users, :password_expires_at, :datetime
  end

  def self.down
    remove_column :users, :issued_at
    remove_column :users, :password_expires_at
  end
end
