class AddIssuedAtAndPasswordUpdatedAtToUser < ActiveRecord::Migration
  def self.up
    add_column :users, :issued_at, :datetime
    add_column :users, :last_password_updated_at, :datetime
  end

  def self.down
    remove_column :users, :issued_at
    remove_column :users, :last_password_updated_at
  end
end
