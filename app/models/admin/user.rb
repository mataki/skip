# SKIP(Social Knowledge & Innovation Platform)
# Copyright (C) 2008 TIS Inc.
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program.  If not, see <http://www.gnu.org/licenses/>.

class Admin::User < User
  require 'fastercsv'
  has_many :user_uids, :dependent => :destroy, :class_name => 'Admin::UserUid'
  has_many :openid_identifiers, :dependent => :destroy, :class_name => 'Admin::OpenidIdentifier'

  N_('Admin::User|Admin')
  N_('Admin::User|Name')
  N_('Admin::User|Password confirmation')
  N_('Admin::User|Password')
  N_('Admin::User|Retired')
  N_('Admin::User|Status')

  class << self
    alias :find :find_without_retired_skip
  end

  def self.search_colomns
    "name like :lqs"
  end

  def topic_title
    name_was
  end

  def self.status_select
    STATUSES.map do |status|
      [_("User|Status|#{status}"), status]
    end
  end

  def self.make_users(uploaded_file)
    users = []
    parsed_csv = FasterCSV.parse uploaded_file
    parsed_csv.each do |line|
      user_hash, user_profile_hash, user_uid_hash = make_user_hash_from_csv_line(line)
      users << make_user({:user => user_hash, :user_profile => user_profile_hash, :user_uid => user_uid_hash})
    end
    users
  end

  def self.make_new_user(params = {}, admin = false)
    check_params_keys(params, [:user, :user_profile, :user_uid])
    user = Admin::User.new(params[:user])
    user.admin = admin
    user.status = admin ? 'ACTIVE' : 'UNUSED'
    user_profile = Admin::UserProfile.new(params[:user_profile])
    user_profile.disclosure = true unless params[:user_profile][:disclosure]
    user.user_profile = user_profile
    user_uid = Admin::UserUid.new(params[:user_uid].merge(:uid_type => 'MASTER'))
    user.user_uids << user_uid
    [user, user_profile, user_uid]
  end

  def self.make_user_by_id(params = {}, admin = false)
    check_params_keys(params, [:user])
    user = Admin::User.find(params[:id])
    user.attributes = params[:user]
    if !params[:user][:status].blank? and !user.unused?
      user.status = params[:user][:status]
    end
    user.admin = params[:user][:admin]
    user
  end

  def self.make_user_by_uid(params = {}, admin = false)
    check_params_keys(params, [:user, :user_profile, :user_uid])
    user = Admin::User.find_by_code(params[:user_uid][:uid])
    user.attributes = params[:user]
    user_profile = user.user_profile
    user_profile.attributes = params[:user_profile]
    user_uid = user.user_uids.find_by_uid_type('MASTER')
    user_uid.attributes = params[:user_uid]
    [user, user_profile, user_uid]
  end

  def self.make_user(params = {}, admin = false)
    check_params_keys(params, [:user, :user_profile, :user_uid])
    user = Admin::User.find_by_code(params[:user_uid][:uid])
    if user
      make_user_by_uid(params, admin)
    else
      make_new_user(params, admin)
    end
  end

  def master_user_uid
    user_uids.find_by_uid_type('MASTER')
  end

  private
  def self.make_user_hash_from_csv_line(line)
    line.map! { |column| column.blank? ? '' : column.toutf8 }
    user_hash = {:name => line[1], :password => line[4], :password_confirmation => line[4]}
    user_profile_hash = {:section => line[2], :email => line[3]}
    user_uid_hash ={:uid => line[0]}
    [user_hash, user_profile_hash, user_uid_hash]
  end

  def self.check_params_keys(params, keys)
    keys.each do |key|
      raise ArgumentError.new("#{key} is required in params") unless params.key?(key)
    end
  end
end
