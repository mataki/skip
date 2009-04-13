class AddIssuedAtAndPasswordExpiresAtToUser < ActiveRecord::Migration
  def self.up
    add_column :users, :issued_at, :datetime
    add_column :users, :password_expires_at, :datetime
    User.transaction do
      now = Time.now
      password_expires_at = now.since(90.day)
      User.all.each do |user|
        user.issued_at = now
        user.password_expires_at = password_expires_at
        user.save!
      end
    end
  end

  def self.down
    remove_column :users, :issued_at
    remove_column :users, :password_expires_at
  end

  class User < ActiveRecord::Base
  end
end
