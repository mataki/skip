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

require 'jcode'

class User < ActiveRecord::Base
  include Authentication
  include Authentication::ByCookieToken
  attr_accessor :old_password, :password
  attr_protected :admin, :status

  has_many :group_participations, :dependent => :destroy
  has_many :pictures, :dependent => :destroy
  has_many :user_profile_values, :dependent => :destroy
  has_many :tracks, :order => "updated_on DESC", :dependent => :destroy
  has_one  :user_access, :class_name => "UserAccess", :dependent => :destroy

  has_many :groups, :through => :group_participations

  has_many :bookmark_comments, :dependent => :destroy
  has_many :antennas, :dependent => :destroy
  has_many :user_uids, :dependent => :destroy

  has_many :openid_identifiers

  validates_presence_of :name, :message => 'は必須です'
  validates_length_of :name, :maximum => 60, :message => 'は60桁以内で入力してください'

  validates_presence_of :password, :message => 'は必須です', :if => :password_required?
  validates_confirmation_of :password, :message => 'は確認用パスワードと一致しません', :if => :password_required?
  validates_length_of :password, :within => 6..40, :too_short => 'は%d文字以上で入力してください', :too_long => 'は%d文字以下で入力して下さい', :if => :password_required?

  validates_presence_of :password_confirmation, :message => 'は必須です', :if => :password_required?

  validates_presence_of :email, :message => 'は必須です'
  validates_length_of :email, :maximum => 50, :message => 'は50桁以内で入力してください'
  validates_format_of :email, :message => 'は正しい形式で登録してください', :with => /^([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})$/
  validates_uniqueness_of :email, :case_sensitive => false, :message => 'は既に登録されています。'

  N_('User|Old password')
  N_('User|Password')
  N_('User|Password confirmation')
  # ステータスの状態
  N_('User|Status|ACTIVE')
  N_('User|Status|RETIRED')
  N_('User|Status|UNUSED')
  STATUSES = %w(ACTIVE RETIRED UNUSED)

  N_('User|Admin|true')
  N_('User|Admin|false')

  N_('User|Disclosure|true')
  N_('User|Disclosure|false')

  ACTIVATION_LIFETIME = 5

  def to_s
    return 'uid:' + uid.to_s + ', name:' + name.to_s
  end

  class << self
    HUMANIZED_ATTRIBUTE_KEY_NAMES = {
      "uid" => "ユーザ名",
      "code" => Admin::Setting.login_account,
      "name" => "名前",
      "section" => "所属",
      "email" => "メールアドレス",
    }
    def human_attribute_name(attribute_key_name)
      HUMANIZED_ATTRIBUTE_KEY_NAMES[attribute_key_name] || super
    end
    def symbol_type
      :uid
    end
    def find_with_retired_skip(*args)
      with_scope(:find => { :conditions => { :status => ['ACTIVE', 'RETIRED']} }) do
        find_without_retired_skip(*args)
      end
    end
    alias_method_chain :find, :retired_skip
  end

  def before_validation
    self.section = self.section.tr('ａ-ｚＡ-Ｚ１-９','a-zA-Z1-9').upcase unless self.section.blank?
  end

  def before_save
    self.crypted_password = encrypt(password) if password_required?
  end

  def self.auth(code_or_email, password)
    return nil unless user = find_by_code_or_email(code_or_email)
    return nil if user.unused?
    if user.crypted_password == encrypt(password)
      user.last_authenticated_at = Time.now
      user
    end
  end

  # Viewで使う所属一覧（セレクトボタン用）
  def self.grouped_sections
    all(:select => "section", :group => "section").collect { |user| user.section }
  end

  def self.encrypt(password)
    Digest::SHA1.hexdigest("#{INITIAL_SETTINGS['sha1_digest_key']}--#{password}--")
  end

  def self.new_with_identity_url(identity_url, params)
    params ||= {}
    code = params.delete(:code)
    password = encrypt(params[:code])
    user = new(params.slice(:name, :email).merge(:password => password, :password_confirmation => password))
    user.user_uids << UserUid.new(:uid => code, :uid_type => 'MASTER')
    user.openid_identifiers << OpenidIdentifier.new(:url => identity_url)
    user.status = 'UNUSED'
    user
  end

  def self.create_with_identity_url(identity_url, params)
    user = new_with_identity_url(identity_url, params)
    user.save
    user
  end

  # 未登録ユーザも含めて検索する際に利用する
  def self.find_by_code(code)
    find_without_retired_skip(:first,
                              :include => :user_uids,
                              :conditions => ["user_uids.uid = ? and user_uids.uid_type = ?", code, 'MASTER'])
  end

  def self.find_by_auth_session_token(token)
    find_without_retired_skip(:first,
                              :include => :user_uids,
                              :conditions => { :auth_session_token => token })
  end

  def self.find_by_activation_token(token)
    find_without_retired_skip(:first,
                              :include => :user_uids,
                              :conditions => { :activation_token => token })
  end

  # 登録済みユーザのユーザID(ログインID,ユーザ名)をもとにユーザを検索する
  def self.find_by_uid(code)
    find(:first, :conditions => ['user_uids.uid = ?', code], :include => :user_uids)
  end

  def change_password(params = {})
    if params[:old_password] and crypted_password == encrypt(params[:old_password])
      if params[:password].blank?
        errors.add(:password, "が入力されていません。")
      else
        self.update_attributes params.slice(:password, :password_confirmation)
      end
    else
      errors.add(:old_password, "が間違っています。")
    end
  end

  def symbol_id
    uid
  end

  def symbol
    self.class.symbol_type.to_s + ":" + symbol_id
  end

  def before_access
    before_access_time = Time.now - user_access.last_access
    before_access_time = 0 if before_access_time < 0

    days = before_access_time.divmod(24*60*60) #=> [2.0, 45000.0]
    hours = days[1].divmod(60*60) #=> [12.0, 1800.0]
    mins = hours[1].divmod(60) #=> [30.0, 0.0]

    days = days[0].to_i
    hours = hours[0].to_i
    mins = mins[0].to_i

    if days >= 180
      "約半年以上アクセスなし"
    elsif days >= 90
      "約3ヶ月以上アクセスなし"
    elsif days >= 10
      "10日以上"
    elsif days >= 1
      "#{days} 日以内"
    elsif hours >= 1
      "#{hours} 時間以内"
    elsif mins >= 1
      "#{mins} 分以内"
    else
      "1分以内"
    end
  end

  def mark_track(visitor_id)
    track = Track.find(:first, :conditions => ["user_id = ? and visitor_id = ?", id, visitor_id], :order => "updated_on DESC")
    if track && (track.updated_on.strftime("%Y %m %d") == Date.today.strftime("%Y %m %d"))
      track.update_attribute("updated_on", Time.now)
    else
      Track.create(:user_id => id, :visitor_id => visitor_id)
    end

    user_access.update_attribute('access_count', user_access.access_count + 1)

    if Track.count(:conditions => ["user_id = ?", id]) > 30
      Track.find(:first, :conditions => ["user_id = ?", id], :order => "updated_on ASC").destroy
    end
  end

  def as_json
    return "{ 'symbol': '#{symbol}', 'name': '#{name}' }"
  end

  def get_postit_url
    "/user/" + self.uid
  end

  def self.select_columns
    return column_names.dup.map! {|item| "users." + item}.join(',')
  end

  def uid
    user_uid = user_uids.find(:first, :conditions => ['uid_type = ?', UserUid::UID_TYPE[:username]])
    user_uid ? user_uid.uid : code
  end

  def code
    user_uid = user_uids.find(:first, :conditions => ['uid_type = ?', UserUid::UID_TYPE[:master]])
    user_uid ? user_uid.uid : nil
  end

  # ユーザ登録時にブログを投稿する
  def create_initial_entry message
    entry_params = {}
    entry_params[:title] ="ユーザー登録しました！"
    entry_params[:message] = message
    entry_params[:tags] = ""
    entry_params[:user_symbol] = symbol
    entry_params[:user_id] = id
    entry_params[:entry_type] = BoardEntry::DIARY
    entry_params[:owner_symbol] = symbol
    entry_params[:publication_type] = 'public'
    entry_params[:publication_symbols] = [Symbol::SYSTEM_ALL_USER]
    entry_params[:editor_mode] = 'richtext'

    BoardEntry.create_entry(entry_params)
  end

  def retired?
    status == 'RETIRED'
  end

  def active?
    status == 'ACTIVE'
  end

  def unused?
    status == 'UNUSED'
  end

  def delete_auth_tokens!
    self.auth_session_token = nil
    self.forget_me
  end

  def update_auth_session_token!
    self.auth_session_token = self.class.make_token
    save(false)
    self.auth_session_token
  end

  def issue_reset_auth_token(since = 24.hour)
    self.reset_auth_token = self.class.make_token
    self.reset_auth_token_expires_at = Time.now.since(since)
  end

  def determination_reset_auth_token
    update_attributes(:reset_auth_token => nil, :reset_auth_token_expires_at => nil)
  end

  def issue_activation_code
    self.activation_token = self.class.make_token
    self.activation_token_expires_at = Time.now.since(self.class.activation_lifetime.day)
  end

  def activate!
    self.activation_token = nil
    self.activation_token_expires_at = nil
    self.save!
  end

  def self.activation_lifetime
    Admin::Setting.activation_lifetime
  end

  def within_time_limit_of_activation_token?
    !self.activation_token.nil? && Time.now <= self.activation_token_expires_at
  end

  def within_time_limit_of_reset_auth_token?
    !self.reset_auth_token.nil? && Time.now <= self.reset_auth_token_expires_at
  end

  def find_or_initialize_profiles(params)
    UserProfileMaster.all.map do |master|
      profile_value = user_profile_values.find_or_initialize_by_user_profile_master_id(master.id)
      profile_value.value = params[master.id.to_s] || ""
      profile_value
    end
  end

  # ユーザが所属するグループのシンボルを配列で返す
  def group_symbols
    @group_symbols ||= GroupParticipation.get_gid_array_by_user_id(self.id)
  end

  # ユーザが所属するシンボル(本人 + 本人の所属するグループ)のシンボルを配列で返す
  def belong_symbols
    @belong_symbols ||= [self.symbol] + self.group_symbols
  end

protected
  # TODO: self.make_conditionsメソッドは使ってなさそう確認して消す
  @@search_cond_keys = [:name, :section, :email]

  def self.make_conditions(options={})
    options.assert_valid_keys @@search_cond_keys

    conditions_state = ""
    conditions_param = []

    @@search_cond_keys.each do |key|
      value = options[key] || ""
      if conditions_state != ""
        conditions_state << " and "
      end
      conditions_state << table_name + "." + key.to_s + " like ?"
      conditions_param << SkipUtil.to_like_query_string(value)
    end
    return conditions_param.unshift(conditions_state)
  end

private
  def password_required?
    active? and crypted_password.blank? or !password.blank?
  end

  def encrypt(password)
    self.class.encrypt(password)
  end

  def self.find_by_code_or_email(code_or_email)
    find_by_code(code_or_email) || find_by_email(code_or_email)
  end
end
