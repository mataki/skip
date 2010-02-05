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

class Group < ActiveRecord::Base
  include SkipEmbedded::LogicalDestroyable

  belongs_to :tenant
  has_many :group_participations, :dependent => :destroy
  has_many :users, :through => :group_participations, :conditions => ['group_participations.waiting = ?', false]
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

  named_scope :partial_match_name_or_description, proc {|word|
    return {} if word.blank?
    {:conditions => ["name LIKE ? OR description LIKE ?", SkipUtil.to_lqs(word), SkipUtil.to_lqs(word)]}
  }

  named_scope :categorized, proc {|category_id|
    return {} if category_id.blank? || category_id == 'all'
    {:conditions => ['group_category_id = ?', category_id]}
  }

  # TODO joinedにリネームする
  named_scope :participating, proc {|user|
    return {} unless user
    {
      :conditions => ["group_participations.user_id = ? AND group_participations.waiting = 0", user.id],
      :include => [:group_participations]
    }
  }

  named_scope :unjoin, proc {|user|
    return {} unless user
    join_group_ids = Group.participating(user).map(&:id)
    return {} if join_group_ids.blank?
    {:conditions => ["groups.id NOT IN (?)", join_group_ids]}
  }

  named_scope :owned, proc { |user|
    {:conditions => ["group_participations.user_id = ? AND group_participations.owned = 1", user.id], :include => :group_participations}
  }

  named_scope :has_waiting_for_approval, proc {
    {
      :conditions => ["group_participations.waiting = 1"],
      :include => [:group_participations]
    }
  }

  named_scope :recent, proc { |day_count|
    { :conditions => ['created_on > ?', Time.now.ago(day_count.to_i.day)] }
  }

  named_scope :order_participate_recent, proc {
    { :order => "group_participations.created_on DESC" }
  }

  named_scope :order_recent, proc { { :order => 'groups.created_on DESC' } }

  named_scope :order_active, proc {
    {
      :joins => "LEFT OUTER JOIN board_entries ON board_entries.symbol = CONCAT('gid:', groups.gid)",
      :group => 'groups.id',
      :order => 'MAX(board_entries.updated_on) DESC'
    }
  }

  named_scope :limit, proc { |num| { :limit => num } }

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

  def self.has_waiting_for_approval owner
    Group.active.owned(owner) & Group.active.has_waiting_for_approval
  end

  def owners
    group_participations.active.only_owned.order_new.map(&:user)
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

  def after_save
    if protected_was == true and protected == false
      self.group_participations.waiting.each{ |p| p.update_attributes(:waiting => false)}
    end
  end

  def administrator?(user)
    Group.owned(user).participating(user).map(&:id).include?(self.id)
  end

  def self.synchronize_groups ago = nil
    conditions = ago ? ['updated_on >= ?', Time.now.ago(ago.to_i.minute)] : []
    Group.scoped(:conditions => conditions).all.map { |g| [g.gid, g.gid, g.name, User.joined(g).map { |u| u.openid_identifier }, !!g.deleted_at] }
  end

  # TODO 回帰テスト書きたい
  def join user_or_users, options = {}
    Group.transaction do
      [user_or_users].flatten.map do |target_user|
        participation = self.group_participations.find_or_initialize_by_user_id(target_user.id) do |participation|
          participation.waiting = (!options[:force] && self.protected?)
        end
        if participation.new_record?
          participation.save!
          target_user.notices.create!(:target => self) unless target_user.notices.find_by_target_id(self.id)
          participation
        else
          self.errors.add_to_base _("%s has already joined / applied to join this group.") % target_user.name
          nil
        end
      end.compact
    end
  rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotSaved => e
    self.errors.add_to_base _('Joined the group failed.')
    false
  end

  # TODO 回帰テスト書きたい
  def leave user
    Group.transaction do
      if participation = self.group_participations.find_by_user_id(user.id)
        participation.destroy
        if notice = user.notices.find_by_target_id(self.id)
          notice.destroy
        end
        if block_given?
          yield true
        else
          true
        end
      else
        if block_given?
          yield false
        else
          false
        end
      end
    end
  end

  def to_param
    gid
  end
end
