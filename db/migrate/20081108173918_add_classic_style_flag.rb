class AddClassicStyleFlag < ActiveRecord::Migration
  def self.up
    add_column :user_customs, :classic, :boolean, :default => false
    User.all.each do |u|
      if uc = UserCustom.find_by_user_id(u.id)
        uc.classic = true
        uc.save(false)
      else
        uc = UserCustom.new(:user_id => u.id, :classic => true)
        uc.save(false)
      end
    end
  end

  def self.down
    remove_column :user_customs, :classic
  end
end
