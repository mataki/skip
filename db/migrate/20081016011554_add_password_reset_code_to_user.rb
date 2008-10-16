class AddPasswordResetCodeToUser < ActiveRecord::Migration
  def self.up
    add_column :users, :password_reset_code, :string

    add_index :users, :password_reset_code
  end

  def self.down
    remove_column :users, :password_reset_code
  end
end
