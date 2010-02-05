class Tenant < ActiveRecord::Base
  has_many :users, :dependent => :destroy
  has_many :board_entries, :dependent => :destroy
  has_many :share_files, :dependent => :destroy
  has_many :groups, :dependent => :destroy
  has_many :group_categories, :dependent => :destroy
end
