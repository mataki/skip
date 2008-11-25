class MoveColumnsFromUsersToUserProfiles < ActiveRecord::Migration
  def self.up
    # カラム追加
    change_table :user_profiles do |t|
      t.string :email,        :limit => 100
      t.string :section,      :limit => 100
      t.string :extension,    :limit => 100
      t.text :self_introduction
    end

    # データ移行
    User.transaction do
      User.find_without_retired_skip(:all).each do |user|
        attrbutes = {:email => user.email, :section => user.section}
        if user.user_profile
          attrbutes.merge!({:extension => user.extension, :self_introduction => user.introduction})
          user.user_profile.update_attributes!(attrbutes)
        else
          user_profile = UserProfile.new(attrbutes.merge!({:disclosure => true}))
          user.user_profile = user_profile
          user.save!
        end
      end
    end

    # カラム除去
    change_table :users do |t|
      t.remove :email, :section, :extension, :introduction
    end
  end

  def self.down
    # カラム追加
    change_table :users do |t|
      t.string :email,        :limit => 100
      t.string :section,      :limit => 100
      t.string :extension,    :limit => 100
      t.text :introduction
    end

    UserProfile.transaction do
      UserProfile.all.each do |user_profile|
        user_profile.user.update_attributes!({:email => user_profile.email, :section => user_profile.section,
                                              :introduction => user_profile.self_introduction, :extension => user_profile.extension})
        user_profile.destroy if user_profile.user.unused?
      end
    end

    # カラム除去
    change_table :user_profiles do |t|
      t.remove :email, :section, :extension, :self_introduction
    end
  end
end
