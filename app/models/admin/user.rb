# SKIP(Social Knowledge & Innovation Platform)
# Copyright (C) 2008-2010 TIS Inc.
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
  has_many :user_profile_values, :dependent => :destroy, :class_name => 'Admin::UserProfileValue'
  has_one :picture, :dependent => :destroy, :class_name => 'Admin::Picture'

  N_('Admin::User|Code')
  N_('Admin::User|Code description')
  N_('Admin::User|Uid')
  N_('Admin::User|Admin')
  N_('Admin::User|Admin description')
  N_('Admin::User|Name')
  N_('Admin::User|Name description')
  N_('Admin::User|Email')
  N_('Admin::User|Email description')
  N_('Admin::User|Section')
  N_('Admin::User|Section description')
  N_('Admin::User|Password confirmation')
  N_('Admin::User|Password')
  N_('Admin::User|Retired')
  N_('Admin::User|Status')
  N_('Admin::User|Status description')
  N_('Admin::User|Locked')
  N_('Admin::User|Locked description')
  N_('Admin::User|Issued at')
  N_('Admin::User|Last authenticated at')
  N_('Admin::User|Password expires at')

  N_('Admin::User|User uids')

  N_('Admin::User|Picture data')
  N_('Admin::User|Picture name')

  class << self
    include InitialSettingsHelper
    alias :find :find_without_retired_skip
  end

  def self.search_columns
    %w(name)
  end

  def topic_title
    name_was
  end

  def self.status_select
    STATUSES.map do |status|
      [_("User|Status|#{status}"), status]
    end
  end

  def self.make_users(uploaded_file, options, create_only = false)
    users = []
    parsed_csv = FasterCSV.parse uploaded_file
    parsed_csv.each do |line|
      user_hash, user_uid_hash = make_user_hash_from_csv_line(line, options)
      user = make_user({:user => user_hash, :user_uid => user_uid_hash}, false, create_only)
      users << user if user
    end
    users
  end

  def self.make_new_user(params, admin = false)
    check_params_keys(params, [:user, :user_uid])
    user = Admin::User.new(params[:user])
    user.admin = admin
    user.status = admin ? 'ACTIVE' : 'UNUSED'
    user_uid = Admin::UserUid.new(params[:user_uid].merge(:uid_type => 'MASTER'))
    user.user_uids << user_uid
    [user, user_uid]
  end

  def self.make_user_by_id(params, admin = false)
    check_params_keys(params, [:user])
    user = Admin::User.find(params[:id])
    user.attributes = params[:user]
    if !params[:user][:status].blank? and !user.unused?
      user.status = params[:user][:status]
    end
    user.admin = params[:user][:admin]
    user
  end

  def self.make_user_by_uid(params, admin = false)
    check_params_keys(params, [:user, :user_uid])
    user = Admin::User.find_by_code(params[:user_uid][:uid])
    user.attributes = params[:user]
    user_uid = user.user_uids.find_by_uid_type('MASTER')
    [user, user_uid]
  end

  def self.make_user(params, admin = false, create_only = false)
    user = Admin::User.find_by_code(params[:user_uid][:uid])
    if user
      params = {:user => {}, :user_uid => {:uid => params[:user_uid][:uid]}} if create_only
      make_user_by_uid(params, admin)
    else
      make_new_user(params, admin)
    end
  end

  def master_user_uid
    user_uids.find_by_uid_type('MASTER')
  end

  def self.lock_actives
    enable_forgot_password? ? update_all('locked = 1, auth_session_token = NULL, remember_token = NULL, remember_token_expires_at = NULL', ['status = ?', 'ACTIVE']) : 0
  end

  def self.reset_all_password_expiration_periods
    update_all("password_expires_at = '#{Admin::Setting.password_change_interval.day.since.to_formatted_s(:db)}'", ['status = ?', 'ACTIVE'])
  end

  def to_param
    id.to_s
  end

  private
  # ログインIDは必須でそれ以外は、optionsにパラメータのあるものを
  # それぞれ正しいHashに設定する
  def self.make_user_hash_from_csv_line(line, options)
    line.map! { |column| column.blank? ? '' : column.toutf8 }

    line_hash = {:login_id => line[0]}
    line_index = 1
    [:name, :email, :section].each do |attr|
      if options && options.include?(attr)
        line_hash[attr] = line[line_index]
        line_index += 1
      end
    end

    user_uid_hash = {}
    user_uid_hash.merge!(:uid => line_hash[:login_id])

    user_hash = {}
    user_hash.merge!(:name => line_hash[:name]) if line_hash[:name]
    user_hash.merge!(:email => line_hash[:email]) if line_hash[:email]
    user_hash.merge!(:section => line_hash[:section]) if line_hash[:section]


    [user_hash, user_uid_hash]
  end

  def self.check_params_keys(params, keys)
    keys.each do |key|
      raise ArgumentError.new("#{key} is required in params") unless params.key?(key)
    end
  end
end
