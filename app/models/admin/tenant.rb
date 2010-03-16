class Admin::Tenant < ActiveRecord::Base
  has_many :users, :class_name => 'Admin::User', :dependent => :destroy
  has_many :board_entries, :class_name => 'Admin::BoardEntry', :dependent => :destroy
  has_many :share_files, :class_name => 'Admin::ShareFile', :dependent => :destroy
  has_many :groups, :class_name => 'Admin::Group', :dependent => :destroy
  has_many :group_categories, :class_name => 'Admin::GroupCategory', :dependent => :destroy
  has_many :user_profile_master_categories, :class_name => 'Admin::UserProfileMasterCategory', :dependent => :destroy
  has_many :user_profile_masters, :class_name => 'Admin::UserProfileMaster', :dependent => :destroy
end
