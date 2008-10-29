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

class User < ActiveRecord::Base
  include Authentication
  include Authentication::ByCookieToken
  attr_accessor :old_password, :password
  attr_protected :admin, :status

  has_many :group_participations, :dependent => :destroy
  has_many :pictures, :dependent => :destroy
  has_one  :user_profile, :dependent => :destroy, :validate => true
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

  N_('User|Old password')
  # ステータスの状態
  N_('User|Status|ACTIVE')
  N_('User|Status|RETIRED')
  N_('User|Status|UNUSED')
  STATUSES = %w(ACTIVE RETIRED UNUSED)

  N_('User|Admin|true')
  N_('User|Admin|false')

  N_('User|Disclosure|true')
  N_('User|Disclosure|false')

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
      "extension" => "内線"
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

  def before_save
    self.crypted_password = encrypt(password) if password_required?
  end

  def self.auth(code, password)
    user = find_by_code(code)
    user if user && user.crypted_password == encrypt(password)
  end

  def self.encrypt(password)
    Digest::SHA1.hexdigest("#{INITIAL_SETTINGS['sha1_digest_key']}--#{password}--")
  end

  def self.new_with_identity_url(identity_url, params)
    params ||= {}
    code = params.delete(:code)
    password = encrypt(params[:code])
    user = new(params.slice(:name).merge(:password => password, :password_confirmation => password))
    user.user_uids << UserUid.new(:uid => code, :uid_type => 'MASTER')
    user.user_profile = UserProfile.new(params.slice(:email).merge(:disclosure => false))
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
      track.update_attribute("visitor_id", visitor_id)
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

  # uidかe-maiかを判断し、適切なユーザを返す
  def self.find_by_login_key login_key
    return login_key.include?('@') ? User.find_by_email(login_key) : User.find_by_uid(login_key)
  end

  # プロフィールを返す（プロパティでキャッシュする）
  def profile
    unless @profile
      if self.user_profile.nil?
        @profile =  UserProfile.new_default
      else
        @profile =  self.user_profile
      end
    end
    return @profile
  end

  # 属性情報とオフ情報のプロフィールを入力しているかどうか
  def has_profile?
    !self.user_profile.nil?
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

  def forgot_password
    self.password_reset_token = self.class.make_token
    self.password_reset_token_expires_at = Time.now.since(24.hour)
  end

  def reset_password
    update_attributes(:password_reset_token => nil, :password_reset_token_expires_at => nil)
  end

protected
  @@search_cond_keys = [:name, :extension, :section, :code, :email, :introduction]

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
    crypted_password.blank? || !password.blank?
  end

  def encrypt(password)
    self.class.encrypt(password)
  end
end
