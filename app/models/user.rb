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
  include ActionController::UrlWriter

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

  with_options(:if => :password_required?) do |me|
    me.validates_presence_of :password
    me.validates_confirmation_of :password
    me.validates_length_of :password, :within => 6..40
    me.validates_presence_of :password_confirmation
  end

  validates_presence_of :email, :message => 'は必須です'
  validates_length_of :email, :maximum => 50, :message => 'は50桁以内で入力してください'
  validates_format_of :email, :message => 'は正しい形式で登録してください', :with => Authentication.email_regex
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

  N_('User|Locked|true')
  N_('User|Locked|false')

  ACTIVATION_LIFETIME = 5

  named_scope :admin, :conditions => {:admin => true}
  named_scope :active, :conditions => {:status => 'ACTIVE'}

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

  def validate
    if password_required?
      errors.add(:password, _('はログインIDと同一の値は登録できません。')) if self.uid == self.password
      errors.add(:password, _('は前回と同一の値は登録できません。')) if self.crypted_password_was == encrypt(self.password)
      errors.add(:password, Admin::Setting.password_strength_validation_error_message) unless Admin::Setting.password_strength_regex.match(self.password)
    end
  end

  def before_save
    if password_required?
      self.crypted_password = encrypt(password)
      self.password_expires_at = Time.now.since(Admin::Setting.password_change_interval.day)
      self.reset_auth_token = nil
      self.reset_auth_token_expires_at = nil
      self.locked = false
      self.trial_num = 0
    end

    if !self.locked_was && self.locked
      self.auth_session_token = nil
      self.remember_token = nil
      self.remember_token_expires_at = nil
    end
  end

  def before_create
    self.issued_at = Time.now
  end

  def after_save
    self.password = nil
    self.password_confirmation = nil
    self.old_password = nil
  end

  def self.auth(code_or_email, password, key_phrase = nil)
    return nil unless user = find_by_code_or_email_with_key_phrase(code_or_email, key_phrase)
    return nil if user.unused?
    if user.crypted_password == encrypt(password)
      auth_successed(user)
    else
      auth_failed(user)
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
    if Admin::Setting.enable_single_session || self.auth_session_token.blank?
      self.auth_session_token = self.class.make_token
    end
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
    self.save_without_validation!
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

  def belong_symbols_with_collaboration_apps
    symbols = ['sid:allusers'] + belong_symbols
    (INITIAL_SETTINGS['belong_info_apps'] || {}).each do |app_name, setting|
      join_info = WebServiceUtil.open_service_with_url(setting["url"], { :user => self.openid_identifier }, setting["ca_file"])
      symbols += join_info.map{|item| item["publication_symbols"]} if join_info
    end
    # TODO: 外のアプリの全公開のコンテンツは、"public"とする。今後、Symbol::SYSTEM_ALL_USERを単に、"public"に変更する。
    symbols << "public"
  end

  # プロフィールボックスに表示するユーザの情報
  def info
    @info ||= { :access_count => self.user_access.access_count,
                :subscriber_count => AntennaItem.count(
                  :conditions => ["antenna_items.value = ?", self.symbol],
                  :select => "distinct user_id",
                  :joins => "left outer join antennas on antenna_id = antennas.id"),
                :blog_count => BoardEntry.count(:conditions => ["user_id = ? and entry_type = ?", self.id, "DIARY"]),
                :using_day => ((Time.now - self.created_on) / (60*60*24)).to_i + 1 }
  end

  def openid_identifier
    identity_url(:user => self.code, :protocol => Admin::Setting.protocol_by_initial_settings_default, :host => Admin::Setting.host_and_port_by_initial_settings_default)
  end

  def to_s_log message
    self.class.to_s_log message, self.uid, self.id
  end

  def self.to_s_log message, uid, user_id = nil
    if user_id
      "#{message}: {\"user_id\" => \"#{user_id}\", \"uid\" => \"#{uid}\"}"
    else
      "#{message}: {\"uid\" => \"#{uid}\"}"
    end
  end

  def locked?
    self.locked
  end

  def within_time_limit_of_password?
    if Admin::Setting.enable_password_periodic_change
      self.password_expires_at && Time.now <= self.password_expires_at
    else
      true
    end
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
    if INITIAL_SETTINGS['login_mode'] == 'password'
      active? and crypted_password.blank? or !password.blank?
    else
      false
    end
  end

  def encrypt(password)
    self.class.encrypt(password)
  end

  def self.find_by_code_or_email(code_or_email)
    find_by_code(code_or_email) || find_by_email(code_or_email)
  end

  def self.find_by_code_or_email_with_key_phrase(code_or_email, key_phrase)
    if Admin::Setting.enable_login_keyphrase
      find_by_code_or_email(code_or_email) if Admin::Setting.login_keyphrase == key_phrase
    else
      find_by_code_or_email(code_or_email)
    end
  end

  def self.auth_successed user
    unless user.locked?
      user.last_authenticated_at = Time.now
      user.trial_num = 0
      user.save(false)
    end
    user
  end

  def self.auth_failed user
    if !user.locked? && Admin::Setting.enable_user_lock
      if user.trial_num < Admin::Setting.user_lock_trial_limit
        user.trial_num += 1
        user.save(false)
      else
        user.locked = true
        user.save(false)
        user.logger.info(user.to_s_log('[User Locked]'))
      end
    end
    nil
  end

  private_class_method :find_by_code_or_email, :find_by_code_or_email_with_key_phrase, :auth_successed, :auth_failed
end
