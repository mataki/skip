class AddActivationTokenToUser < ActiveRecord::Migration
  def self.up
    add_column :users, :activation_token, :string
    add_column :users, :activation_token_expires_at, :datetime

    add_index :users, :activation_token
  end

  def self.down
    remove_column :users, :activation_token
    remove_column :users, :activation_token_expires_at
  end
end
