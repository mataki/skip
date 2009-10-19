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

class Group < ActiveRecord::Base
  include SkipEmbedded::LogicalDestroyable

  has_many :group_participations, :dependent => :destroy
  belongs_to :group_category

  validates_presence_of :name, :description, :gid
  validates_uniqueness_of :gid, :case_sensitive => false
  validates_length_of :gid, :within => 4..50
  validates_format_of :gid, :message => _("accepts numbers, alphabets, hiphens(\"-\") and underscores(\"_\")."), :with => /^[a-zA-Z0-9\-_]*$/
  validates_inclusion_of :default_publication_type, :in => ['public', 'private']

  N_('Group|Protected|true')
  N_('Group|Protected|false')

  named_scope :partial_match_gid, proc {|word|
    {:conditions => ["gid LIKE ?", SkipUtil.to_lqs(word)]}
  }
  named_scope :partial_match_gid_or_name, proc {|word|
    {:conditions => ["gid LIKE ? OR name LIKE ?", SkipUtil.to_lqs(word), SkipUtil.to_lqs(word)]}
  }
  named_scope :participating, proc {|user|
    return {} unless user
    {:conditions => ["group_participations.user_id = ? AND group_participations.waiting = 0", user.id], :include => :group_participations}
  }

  named_scope :order_participate_recent, proc {
    { :order => "group_participations.created_on DESC" }
  }

  named_scope :limit, proc { |num| { :limit => num } }

  named_scope :recent, proc { |day_count|
    { :conditions => ['created_on > ?', Time.now.ago(day_count.to_i.day)] }
  }

  named_scope :order_recent, proc { { :order => 'created_on DESC' } }

  named_scope :owned, proc { |user|
    {:conditions => ["group_participations.user_id = ? AND group_participations.owned = 1", user.id], :include => :group_participations}
  }

  alias initialize_old initialize

  def initialize(attributes = nil)
    attributes = {} if attributes.nil?
    if attributes[:group_category_id].nil?
      if gc = GroupCategory.find_by_initial_selected(true)
        attributes[:group_category_id] = gc.id
      end
    end
    initialize_old(attributes)
  end

  class << self
    def symbol_type
      :gid
    end
  end

  def validate
    unless GroupCategory.find_by_id(self.group_category_id)
      errors.add(:group_category_id, _('Category not selected or value invalid.'))
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
    entry_params[:title] =_("Invited to Group: %s") % self.name
    entry_params[:message] = _("You have been invited to join [%s>].") % self.symbol
    entry_params[:tags] = "#{Tag::NOTICE_TAG}"
    entry_params[:user_id] = user_id
    entry_params[:user_symbol] = user_symbol
    entry_params[:entry_type] = BoardEntry::GROUP_BBS
    entry_params[:owner_symbol] = self.symbol
    entry_params[:publication_type] = 'protected'
    entry_params[:publication_symbols] = publication_symbols
    BoardEntry.create_entry entry_params
  end

  def category_icon_name
    [group_category.icon, group_category.name]
  end

  # TODO waitingという名前でnamed_scopeにする
  def self.find_waitings(user_id)
    sub_query = "select group_id from group_participations where waiting = 1"
    participations = GroupParticipation.find(:all, :conditions =>["user_id = ? and owned = 1 and group_id in (#{sub_query})", user_id])
    result = []
    if participations.size > 0
      group_ids =  participations.map {|participation| participation.group_id.to_s }
      result = Group.active.find(:all, :conditions => ["id IN (?)", group_ids])
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
    active(:select => "group_category_id, gid").each{ |group| group_by_category[group.group_category_id] << "gid:#{group.gid}" }
    group_by_category
  end

  # グループに関連する情報の削除
  def after_logical_destroy
    # FIXME [#855][#907]Rails2.3.2のバグでcounter_cacheと:dependent => destoryを併用すると常にStaleObjectErrorとなる
    # SKIPではBoardEntryとBoardEntryCommentの関係が該当する。Rails2.3.5でFixされたら以下を修正すること
    # 詳細は http://dev.openskip.org/redmine/issues/show/855
    board_entry_ids = BoardEntry.scoped(:conditions => ['symbol = ?', self.symbol]).all.map(&:id)
    BoardEntryComment.destroy_all(['board_entry_id in (?)', board_entry_ids])
    BoardEntry.destroy_all(["id in (?)", board_entry_ids])
    ShareFile.destroy_all(["owner_symbol = ?", self.symbol])
  end

  # TODO named_scope化する
  def self.count_by_category user_id = nil
    conditions = user_id ? ['group_participations.user_id = ?', user_id] : []
    groups = active.all(
      :select => 'group_category_id, count(distinct(groups.id)) as count',
      :group => 'groups.group_category_id',
      :conditions => conditions,
      :joins => [:group_participations])
    group_counts = Hash.new(0)
    total_count = 0
    groups.each do |group_count|
      group_counts[group_count.group_category_id] = group_count.count.to_i
      total_count += group_count.count.to_i
    end
    [group_counts, total_count]
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

  # paginateで使う検索条件を作成する
  # TODO 回帰テストを書く
  # TODO named_scope化してwill_paginateに対応させる
  def self.paginate_option target_user_id, params = { :page => 1 }
    conditions = [""]

    if params[:keyword] and not params[:keyword].empty?
      conditions[0] << "(groups.name like ? or groups.description like ?)"
      conditions << SkipUtil.to_lqs(params[:keyword]) << SkipUtil.to_lqs(params[:keyword])
    end

    if params[:yet_participation]
      conditions[0] << " and " unless conditions[0].empty?
      conditions[0] << " NOT EXISTS (SELECT * FROM group_participations gp where groups.id = gp.group_id and gp.user_id = ?) "
      conditions << target_user_id
    elsif params[:participation]
      conditions[0] << " and " unless conditions[0].empty?
      conditions[0] << " group_participations.user_id in (?)"
      conditions << target_user_id
    end

    if group_category_id = params[:group_category_id] and group_category_id != "all"
      conditions[0] << " and " unless conditions[0].empty?
      conditions[0] << "group_category_id = ?"
      conditions << group_category_id
    end

    conditions[0] << " and " unless conditions[0].empty?
    conditions[0] << "deleted_at IS NULL"

    options = {}
    if sort_type = params[:sort_type] and sort_type == "name"
      options[:order] = "groups.name"
    else
      options[:order] = "group_participations.created_on DESC"
    end
    options[:conditions] = conditions unless conditions[0].empty?
    options[:include] = :group_participations
    options
  end

  def administrator?(user)
    Group.owned(user).participating(user).map(&:id).include?(self.id)
  end

  def self.synchronize_groups ago = nil
    conditions = ago ? ['updated_on >= ?', Time.now.ago(ago.to_i.minute)] : []
    Group.scoped(:conditions => conditions).all.map { |g| [g.gid, g.gid, g.name, g.participation_users(:waiting => false).map { |u| u.openid_identifier }, !!g.deleted_at] }
  end

  def self.favorites_per_category user
    favorite_groups = []
    GroupCategory.find(:all).each do |category|
      groups = Group.active.all(
        :conditions => ["group_category_id = ? and group_participations.user_id = ? and group_participations.favorite = true", category.id, user.id],
        :order => "group_participations.created_on DESC",
        :include => :group_participations)
      favorite_groups << {:name => category.name, :groups => groups} if groups.size > 0
    end
    favorite_groups
  end
end
