class AddSimpleLoginTokenAndEnableSimpleLoginToUsers < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
      add_column :users, :simple_login_token, :string
      add_column :users, :simple_login_token_expires_at, :datetime
      add_column :users, :enable_simple_login, :boolean, :default => false
      add_index :users, :simple_login_token, :unique => true
    end

  end

  def self.down
    remove_column :users, :simple_login_token
    remove_column :users, :simple_login_token_expires_at
    remove_column :users, :enable_simple_login
  end
end
