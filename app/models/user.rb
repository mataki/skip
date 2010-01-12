# SKIP(Social Knowledge & Innovation Platform)
# Copyright (C) 2008-2009 TIS Inc.
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
  include ActionController::UrlWriter

  attr_accessor :old_password, :password
  attr_protected :admin, :status
  cattr_reader :per_page
  @@per_page = 40

  has_many :group_participations, :dependent => :destroy
  has_one :picture, :conditions => ['pictures.active = ?', true], :dependent => :destroy
  has_many :pictures, :dependent => :destroy
  has_many :user_profile_values, :dependent => :destroy
  has_many :tracks, :order => "updated_on DESC", :dependent => :destroy
  has_one  :user_access, :class_name => "UserAccess", :dependent => :destroy
  has_one  :user_custom, :dependent => :destroy

  has_many :groups, :through => :group_participations, :conditions => 'groups.deleted_at IS NULL'

  has_many :bookmark_comments, :dependent => :destroy
  has_many :user_uids, :dependent => :destroy

  has_many :openid_identifiers
  has_many :user_oauth_accesses

  has_many :follow_chains, :class_name => 'Chain', :foreign_key => 'from_user_id'
  has_many :against_chains, :class_name => 'Chain', :foreign_key => 'to_user_id'
  has_many :notices, :dependent => :destroy
  has_many :system_messages, :dependent => :destroy

  validates_presence_of :name
  validates_length_of :name, :maximum => 60

  with_options(:if => :password_required?) do |me|
    me.validates_presence_of :password
    me.validates_confirmation_of :password
    me.validates_length_of :password, :within => 6..40
    me.validates_presence_of :password_confirmation
  end

  validates_presence_of :email, :message => _('is mandatory.')
  validates_length_of :email, :maximum => 50
  validates_format_of :email, :message =>_('requires proper format.'), :with => Authentication.email_regex
  validates_uniqueness_of :email, :case_sensitive => false

  named_scope :recent, proc { |day_count|
    { :conditions => ['created_on > ?', Time.now.ago(day_count.to_i.day)] }
  }

  named_scope :order_recent, proc { { :order => 'created_on DESC' } }

  named_scope :limit, proc { |num| { :limit => num } }

  named_scope :joined, proc { |group|
    {
      :conditions => ['group_participations.group_id = ? AND group_participations.waiting = false', group.id],
      :include => [:group_participations]
    }
  }

  named_scope :owned, proc { |group|
    {
      :conditions => ['group_participations.group_id = ? AND group_participations.waiting = false AND group_participations.owned = true', group.id],
      :include => [:group_participations]
    }
  }

  named_scope :joined_except_owned, proc { |group|
    {
      :conditions => ['group_participations.group_id = ? AND group_participations.waiting = false AND group_participations.owned = false', group.id],
      :include => [:group_participations]
    }
  }

  named_scope :name_or_code_like, proc { |word|
    { :conditions => ["user_uids.uid like :word OR users.name like :word", { :word => SkipUtil.to_like_query_string(word) }],
      :include => :user_uids }
  }

  named_scope :profile_like, proc { |profile_master_id, profile_value|
    return {} if profile_value.blank?
    condition_str = ''
    condition_params = []
    unless profile_master_id.to_s == "0" # Anyが選択された場合
      condition_str << 'user_profile_master_id = ? AND '
      condition_params << profile_master_id
    end
    condition_str << 'user_profile_values.value like ? '
    condition_params << SkipUtil.to_like_query_string(profile_value)
    { :conditions => [condition_str, condition_params].flatten, :include => :user_profile_values }
  }

  named_scope :tagged, proc { |tag_words, tag_select|
    return {} if tag_words.blank?
    tag_select = 'AND' unless tag_select == 'OR'
    condition_str = ''
    condition_params = []
    words = tag_words.split(',')
    words.each do |word|
      condition_str << (word == words.last ? ' chains.tags_as_s like ?' : " chains.tags_as_s like ? #{tag_select}")
      condition_params << SkipUtil.to_like_query_string(word)
    end
    { :conditions => [condition_str, condition_params].flatten, :include => :against_chains }
  }

  named_scope :exclude_retired, proc { |flg|
    target = ["ACTIVE"]
    target << "RETIRED" unless flg == "1"
    status_in(target).proxy_options
  }

  named_scope :order_joined, proc { { :order => "group_participations.updated_on DESC" } }

  named_scope :limit, proc { |num| { :limit => num } }

  named_scope :admin, :conditions => {:admin => true}
  named_scope :active, :conditions => {:status => 'ACTIVE'}
  named_scope :partial_match_uid, proc {|word|
    {:conditions => ["users.id in (?)", UserUid.partial_match_uid(word).map{|uu| uu.user_id}], :include => [:user_uids]}
  }
  named_scope :partial_match_uid_or_name, proc {|word|
    {:conditions => ["users.id in (?) OR name LIKE ?", UserUid.partial_match_uid(word).map{|uu| uu.user_id}, SkipUtil.to_lqs(word)], :include => [:user_uids]}
  }
  named_scope :with_basic_associations, :include => [:user_uids, :user_custom]

  named_scope :order_last_accessed, proc {
    { :order => 'user_accesses.last_access DESC', :include => [:user_access] }
  }

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

  N_('User|Uid')

  ACTIVATION_LIFETIME = 5

  def to_s
    return 'uid:' + uid.to_s + ', name:' + name.to_s
  end

  class << self
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

  def validate
    if password_required?
      errors.add(:password, _('shall not be the same with login ID.')) if self.uid == self.password
      errors.add(:password, _('shall not be the same with the previous one.')) if self.crypted_password_was == encrypt(self.password)
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

    user_oauth_accesses.delete_all if retired?
  end

  def self.auth(code_or_email, password, key_phrase = nil)
    unless user = find_by_code_or_email_with_key_phrase(code_or_email, key_phrase)
      result, result_user = false, nil
    else
      if user.unused?
        result, result_user = false, nil
      else
        if user.crypted_password == encrypt(password)
          if user.locked? || !user.within_time_limit_of_password?
            result, result_user = false, user
          else
            result, result_user = true, auth_successed(user)
          end
        else
          result, result_user = false, auth_failed(user)
        end
      end
    end
    yield(result, result_user) if block_given?
    result
  end

  # Viewで使う所属一覧（セレクトボタン用）
  def self.grouped_sections
    all(:select => "section", :group => "section").collect { |user| user.section }
  end

  def self.encrypt(password)
    Digest::SHA1.hexdigest("#{SkipEmbedded::InitialSettings['sha1_digest_key']}--#{password}--")
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
    with_basic_associations.find_without_retired_skip(:first, :conditions => { :auth_session_token => token })
  end

  def self.find_by_activation_token(token)
    find_without_retired_skip(:first,
                              :include => :user_uids,
                              :conditions => { :activation_token => token })
  end

  # 登録済みユーザのユーザID(ログインID,ユーザ名)をもとにユーザを検索する
  def self.find_by_uid(code)
    user = find(:first, :conditions => ['user_uids.uid = ?', code], :include => :user_uids)
    user ? user.reload : user
  end

  def change_password(params = {})
    if params[:old_password] and crypted_password == encrypt(params[:old_password])
      if params[:password].blank?
        errors.add(:password, _("not provided."))
      else
        self.update_attributes params.slice(:password, :password_confirmation)
      end
    else
      errors.add(:old_password, _("incorrect."))
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
      _("Has not accessed for 6 or more months.")
    elsif days >= 90
      _("Has not accessed for 3 or more months.")
    elsif days >= 10
      _("Within 10 days and more")
    elsif days >= 1
      n_("Within %d day", "Within %d days", days) % days
    elsif hours >= 1
      n_("Within %d hour", "Within %d hours", hours) % hours
    elsif mins >= 1
      n_("Within %d minute", "Within %d minutes", mins) % mins
    else
      _("Within a minute")
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
    username || code
  end

  def username
    user_uid = user_uids.detect { |u| u.uid_type == UserUid::UID_TYPE[:username] }
    user_uid ? user_uid.uid : nil
  end

  def code
    user_uid = user_uids.detect { |u| u.uid_type == UserUid::UID_TYPE[:master] }
    user_uid ? user_uid.uid : nil
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

  def self.issue_activation_codes user_ids
    unused_users = []
    active_users = []
    users = User.scoped(:conditions => ['id in (?)', user_ids]).find_without_retired_skip(:all)
    users.each do |u|
      if u.unused?
        u.activation_token = make_token
        u.activation_token_expires_at = Time.now.since(activation_lifetime.day)
        u.save_without_validation!
        unused_users << u
      elsif u.active?
        active_users << u
      end
    end
    yield unused_users, active_users if block_given?
    [unused_users, active_users]
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
    @group_symbols ||= Group.active.participating(self).map(&:symbol)
  end

  # ユーザが所属するシンボル(本人 + 本人の所属するグループ)のシンボルを配列で返す
  def belong_symbols
    @belong_symbols ||= [self.symbol] + self.group_symbols
  end

  def belong_symbols_with_collaboration_apps
    symbols = ['sid:allusers'] + belong_symbols
    (SkipEmbedded::InitialSettings['belong_info_apps'] || {}).each do |app_name, setting|
      join_info = SkipEmbedded::WebServiceUtil.open_service_with_url(setting["url"], { :user => self.openid_identifier }, setting["ca_file"])
      symbols += join_info.map{|item| item["publication_symbols"]} if join_info
    end
    # TODO: 外のアプリの全公開のコンテンツは、"public"とする。今後、Symbol::SYSTEM_ALL_USERを単に、"public"に変更する。
    symbols << "public"
  end

  # プロフィールボックスに表示するユーザの情報
  def info
    @info ||= { :access_count => self.user_access ? self.user_access.access_count : 0,
                :subscriber_count => Notice.subscribed(self).count,
                :blog_count => BoardEntry.count(:conditions => ["user_id = ? and entry_type = ?", self.id, "DIARY"]),
                :using_day => ((Time.now - self.created_on) / (60*60*24)).to_i + 1 }
  end

  def openid_identifier
    identity_url(:user => self.code, :protocol => SkipEmbedded::InitialSettings['protocol'], :host => SkipEmbedded::InitialSettings['host_and_port'])
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

  def self.synchronize_users ago = nil
    conditions = ago ? ['updated_on >= ?', Time.now.ago(ago.to_i.minute)] : []
    User.scoped(:conditions => conditions, :include => :user_uids).find_without_retired_skip(:all).map { |u| [u.openid_identifier, u.uid, u.name, u.admin, u.retired?] }
  end

  def self.find_by_openid_identifier openid_identifier
    return nil if openid_identifier.blank?
    uid = openid_identifier.split('/').last
    User.find_by_uid uid
  end

  def custom
    self.user_custom || self.build_user_custom
  end

  def default_publication_type
    'public'
  end

  def participating_group? group
    raise ArgumentError, 'group_or_gid is invalid' unless group.is_a?(Group)
    self.group_symbols.include? group.symbol
  end

  def to_param
    uid
  end

  def reset_simple_login_token!
    self.simple_login_token = self.class.make_token
    self.simple_login_token_expires_at = Time.now.since(1.month)
    self.save!
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
    if SkipEmbedded::InitialSettings['login_mode'] == 'password'
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
