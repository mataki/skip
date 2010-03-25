class Tenant < ActiveRecord::Base
  has_many :users, :dependent => :destroy
  has_many :board_entries, :dependent => :destroy
  has_many :share_files, :dependent => :destroy
  has_many :groups, :dependent => :destroy
  has_many :group_categories, :dependent => :destroy
  has_one :activation, :dependent => :destroy
  has_many :user_profile_master_categories, :dependent => :destroy
  has_many :user_profile_masters, :dependent => :destroy

  def self.find_by_op_endpoint(endpoint)
    if endpoint.match(/^https:\/\/www\.google\.com\/a\/(.*)\/o8\/ud\?be=o8$/)
      self.find_by_op_url($1)
    else
      self.find_by_op_url(endpoint)
    end
  end
end
