# SKIP（Social Knowledge & Innovation Platform）
# Copyright (C) 2008  TIS Inc.
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

class Group < ActiveRecord::Base
  has_many :group_participations, :dependent => :destroy

  validates_presence_of :name, :description, :gid,
                        :message =>'は必須です'

  validates_uniqueness_of :gid, :message =>'は既に登録されています'
  validates_length_of :gid, :minimum=>4, :message =>'は4文字以上で入力してください'
  validates_length_of :gid, :maximum=>50, :message =>'は50文字以内で入力してください'
  validates_format_of :gid, :message =>'は数字orアルファベットor記号(ハイフン「-」 アンダーバー「_」)で入力してください', :with => /^[a-zA-Z0-9\-_]*$/

  # categoryの種類
  BIZ = "BIZ"
  LIFE = "LIFE"
  OFF = "OFF"
  CATEGORY_KEYS = [BIZ, LIFE, OFF]
  CATEGORY_KEY_NAMES = {
    BIZ => "ビジネス",
    LIFE => "ライフ",
    OFF => "オフ"
  }
  CATEGORY_KEY_ICON_NAMES = {
    BIZ => "page_word",
    LIFE => "group_gear",
    OFF => "ipod"
  }
  CATEGORY_KEY_DESCRIPTIONS = {
    BIZ => "プロジェクト内など、業務で利用する場合に選択してください。",
    LIFE => "業務に直結しない会社内の活動で利用する場合に選択してください。",
    OFF => "趣味などざっくばらんな話題で利用する場合に選択してください。"
  }

  class << self
    HUMANIZED_ATTRIBUTE_KEY_NAMES = {
      "name" => "名前",
      "description" => "説明",
      "gid" => "グループID"
    }
    def human_attribute_name(attribute_key_name)
      HUMANIZED_ATTRIBUTE_KEY_NAMES[attribute_key_name] || super
    end
    def symbol_type
      :gid
    end
  end

  def symbol_id
    gid
  end

  def symbol
    self.class.symbol_type.to_s + ":" + symbol_id
  end

  def to_s
    return 'id:' + id.to_s + ', name:' + name.to_s
  end

  def has_waiting
    if group_participations.find(:all, :conditions =>["waiting = ?", true]).size > 0
      return true
    end
    return false
  end

  def create_entry_invite_group user_id, user_symbol, publication_symbols
    entry_params = { }
    entry_params[:title] ="グループ：#{self.name}に招待しました"
    entry_params[:message] = "[#{self.symbol}>]にあなたを招待しました。"
    entry_params[:tags] = "#{Tag::NOTICE_TAG}"
    entry_params[:user_id] = user_id
    entry_params[:user_symbol] = user_symbol
    entry_params[:entry_type] = BoardEntry::GROUP_BBS
    entry_params[:owner_symbol] = self.symbol
    entry_params[:publication_type] = 'protected'
    entry_params[:publication_symbols] = publication_symbols
    BoardEntry.create_entry entry_params
  end

  def self.category_icon_name category
    [CATEGORY_KEY_ICON_NAMES[category], CATEGORY_KEY_NAMES[category]]
  end

  def category_icon_name
    self.class.category_icon_name category
  end

  def self.make_conditions(options={})
    options.assert_valid_keys [:name, :participation, :participation_group_ids]

    conditions_state = ""
    conditions_param = []

    name = options[:name] || ""
    conditions_state << "name like ?"
    conditions_param << SkipUtil.to_like_query_string(name)

    if options[:participation] and options[:participation_group_ids].size > 0
        conditions_state << " and id not in (?)"
        conditions_param << options[:participation_group_ids]
    end
    return conditions_param.unshift(conditions_state)
  end

  def self.find_waitings(user_id)
    sub_query = "select group_id from group_participations where waiting = 1"
    participations = GroupParticipation.find(:all, :conditions =>["user_id = ? and owned = 1 and group_id in (#{sub_query})", user_id])
    result = []
    if participations.size > 0
      group_ids =  participations.map {|participation| participation.group_id.to_s }
      result = Group.find(:all, :conditions =>["id IN (?)", group_ids] )
    end
    result
  end

  def get_owners
    owners = []
    group_participations.each do |participation|
      owners << participation.user if participation.owned
    end
    return owners
  end

  # グループのカテゴリごとのgidの配列を返す(SQL発行あり)
  #   { "BIZ" => ["gid:swat","gid:qms"], "LIFE" => [] ... }
  def self.gid_by_category
    group_by_category = Hash.new{|h, key| h[key] = []}

    find(:all, :select => "category, gid").each{ |group| group_by_category[group.category] << "gid:#{group.gid}" }
    group_by_category
  end

  # グループに関連する情報の削除
  def after_destroy
    BoardEntry.destroy_all(["symbol = ?", self.symbol])
    ShareFile.destroy_all(["owner_symbol = ?", self.symbol])
  end

  def self.count_by_category user_id=nil
    conditions = user_id ? ['group_participations.user_id = ?', user_id] : []
    groups = find(:all,
                  :select => 'groups.category, count(distinct(groups.id)) as count',
                  :group => 'groups.category',
                  :conditions => conditions,
                  :joins => [:group_participations])
    group_counts = Hash.new(0)
    total_count = 0
    groups.each do |group_count|
      group_counts[group_count.category] = group_count.count.to_i
      total_count += group_count.count.to_i
    end

    return group_counts, total_count
  end

  # グループに所属しているユーザを取得する。
  # :owned trueの場合、管理者のみ。falseの場合、管理者以外
  # :waiting trueの場合、承認待ちユーザのみ。falseの場合承認済みユーザのみ。
  # 引数なしの場合、グループに所属する全てのユーザ(承認待ちユーザも含む)
  def participation_users params = {}
    conditions_state = "group_participations.group_id = ? "
    conditions_param = [self.id]

    unless params[:waiting].nil?
      conditions_state << "and group_participations.waiting = ? "
      conditions_param << params[:waiting]
    end

    unless params[:owned].nil?
      conditions_state << "and group_participations.owned = ? "
      conditions_param << params[:owned]
    end

    options = {}
    options[:conditions] = conditions_param.unshift(conditions_state)
    options[:include] = "group_participations"
    options[:limit] = params[:limit] unless params[:limit].nil?
    options[:order] = params[:order] unless params[:order].nil?

    User.find(:all, options)
  end
end
