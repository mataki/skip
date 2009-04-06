class MoveEmailAndSectionFromUserProfilesToUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :email, :string, :limit => 100
    add_column :users, :section, :string, :limit => 100

    User.transaction do
      User.all.each do |user|
        profile = UserProfile.find_by_user_id(user.id)
        if profile
          user.email = profile.email
          user.section = profile.section
          user.save!
        end
      end
    end

    remove_column :user_profiles, :email
    remove_column :user_profiles, :section
  end

  def self.down
    add_column :user_profiles, :email, :string, :limit => 100
    add_column :user_profiles, :section, :string, :limit => 100

    User.transaction do
      User.all.each do |user|
        profile = UserProfile.find_by_user_id(user.id)
        if profile
          profile.email = user.email
          profile.section = user.section
          profile.save!
        end
      end
    end

    remove_column :users, :email
    remove_column :users, :section
  end

  class User < ActiveRecord::Base
  end

  class UserProfile < ActiveRecord::Base
  end
end
