class AddIssuedAtAndPasswordExpiresAtToUser < ActiveRecord::Migration
  def self.up
    add_column :users, :issued_at, :datetime
    add_column :users, :password_expires_at, :datetime
    User.transaction do
      now = Time.now
      password_expires_at = now.since(90.day)
      Admin::User.all.each do |user|
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
end

class Admin::User < User
  def locked
    lock
  end
  def locked_was
    lock_was
  end
end
