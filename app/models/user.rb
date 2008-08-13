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
  has_many :group_participations, :dependent => :destroy
  has_many :pictures, :dependent => :destroy
  has_one  :user_profile, :dependent => :destroy
  has_many :tracks, :order => "updated_on DESC", :dependent => :destroy
  has_one  :user_access, :class_name => "UserAccess", :dependent => :destroy

  has_many :groups, :through => :group_participations

  has_many :bookmark_comments, :dependent => :destroy
  has_many :antennas, :dependent => :destroy
  has_many :user_uids, :dependent => :destroy

  validates_presence_of :email, :message => 'は必須です'
  validates_length_of :email, :maximum => 50, :message => 'は50桁以内で入力してください'
  validates_format_of :email, :message => 'は正しい形式で登録してください', :with => /^([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})$/

  validates_presence_of :name, :message => 'は必須です'
  validates_length_of :name, :maximum => 60, :message => 'は60桁以内で入力してください'

  validates_presence_of :section, :message => 'は必須です'
  validates_length_of :section, :maximum => 30, :message => 'は30桁以内で入力してください'

  validates_presence_of :extension, :message => 'は必須です'
  validates_numericality_of :extension, :message => 'は数値で入力してください'
  validates_length_of :extension, :maximum => 10, :message => 'は10桁以内で入力してください'

  validates_length_of :introduction, :minimum => 5, :message => 'は5文字数以上入力してください'

  def to_s
    return 'uid:' + uid.to_s + ', name:' + name.to_s
  end

  class << self
    HUMANIZED_ATTRIBUTE_KEY_NAMES = {
      "uid" => "ニックネーム",
      "email" => "メールアドレス",
      "code" => Setting.login_account,
      "name" => "氏名",
      "section" => "部門",
      "extension" => "内線番号",
      "introduction" => "自己紹介"
    }
    def human_attribute_name(attribute_key_name)
      HUMANIZED_ATTRIBUTE_KEY_NAMES[attribute_key_name] || super
    end
    def symbol_type
      :uid
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

  def self.find_by_uid(code)
    find(:first, :conditions => ['user_uids.uid = ?', code], :include => :user_uids)
  end

  def uid
    user_uid = user_uids.find(:first, :conditions => ['uid_type = ?', UserUid::UID_TYPE[:nickname]])
    user_uid ? user_uid.uid : code
  end

  def code
    user_uid = user_uids.find(:first, :conditions => ['uid_type = ?', UserUid::UID_TYPE[:master]])
    user_uid ? user_uid.uid : nil
  end

  def self.find_as_csv(*args)
    users = User.find(*args)

    csv_text = ""
    CSV::Writer.generate(csv_text) do |csv|
      csv << User.get_csv_header
      users.each do |user|
        csv << user.get_csv_record
      end
    end
    csv_text
  end

  def get_csv_record
    SkipUtil.get_a_row_for_csv([code, name, section, extension, email, created_on.strftime("%Y/%m/%d")])
  end

  def self.get_csv_header
    SkipUtil.get_a_row_for_csv([Setting.login_account, '名前', '所属', '内線', 'e-mail', '登録日'])
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

  # プロフィールの更新（ない場合はレコード作成）
  def update_profile(profile_params, hobbies_params)
    hobby = ""
    if hobbies_params && hobbies_params.size > 0
      hobby = hobbies_params.join(',')+','
    end

    if self.user_profile.nil?
      @profile = UserProfile.new(profile_params)
      @profile.user_id = self.id
      @profile.hobby = hobby
      @profile.save
    else
      @profile =  self.user_profile
      @profile.hobby = hobby
      @profile.update_attributes(profile_params)
    end
    return @profile
  end

  # 属性情報とオフ情報のプロフィールを入力しているかどうか
  def has_profile?
    !self.user_profile.nil?
  end

  # Viewで使う部門一覧（セレクトボタン用）
  def self.select_section
    User.find(:all, :select => "section", :group => "section").collect { |user| user.section }
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

end
