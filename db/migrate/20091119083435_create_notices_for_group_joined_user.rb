class CreateNoticesForGroupJoinedUser < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
      User.all.each do |user|
        Group.active.participating(user).each do |group|
          unless notice = user.notices.find_by_target_id(group.id)
            user.notices.create! :target => group
            puts "create notice successful :user_id => #{user.id}, :group_id => #{group.id}."
          else
            puts "skipped :user_id => #{user.id}, :group_id => #{group.id} because notice has been created."
          end
        end
      end
    end
  end

  def self.down
    raise ActiveRecord::IrreversibleMigration
  end

  class ::User < ActiveRecord::Base
    has_many :notices
  end
end
