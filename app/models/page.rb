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

class Page < ActiveRecord::Base
  include SkipEmbedded::LogicalDestroyable
  acts_as_tree

  CRLF = /\r?\n/

  attr_reader :new_history

  has_many :histories, :order => "histories.revision DESC"
  has_many :attachments
  validates_associated :new_history, :if => :new_history, :on => :create
  validates_uniqueness_of :title
  validates_presence_of :title
  validates_inclusion_of :format_type, :in => %w[hiki html]

  after_save :reset_history_caches

  named_scope :fulltext, proc{|keyword|
    hids = History.find_all_by_head_content(keyword).map(&:page_id)
    if hids.empty?
      { :conditions => "1 = 2" } # force false
    else
      { :conditions => ["#{quoted_table_name}.id IN (?)", hids] }
    end
  }

  named_scope :admin_fulltext, proc{|keyword|
    return {} if keyword.blank?
    w = "%#{keyword}%"

    hids = History.find_all_by_head_content(keyword).map(&:page_id)
    if hids.empty?
      { :conditions => ["#{quoted_table_name}.display_name LIKE ?", w] } # force false
    else
      { :conditions => ["#{quoted_table_name}.id IN (?) OR #{quoted_table_name}.display_name LIKE ?", hids, w] }
    end
  }

  def root?
    self.class.roots.include?(self) || self.parent_id == 0
  end

  def has_history?
    !(self.last_modified_user_id == 0)
  end

  def content(revision=nil)
    if revision.nil?
      (history = @new_history || head) ? history.content.data : ""
    else
      histories.detect{|h| h.revision ==revision.to_i }.content.data
    end
  end

  def chapters
    head ? head.content.chapters : nil
  end

  def head
    histories.first
  end

  def edit(content, user)
    return if content.data == self.content and !(revision == 0)
    self.updated_at = Time.now.utc
    @new_history = histories.build(:content => content,
                                   :user => user,
                                   :revision => revision.succ)
  end

  def revision
    new_record? ? 0 :(@revision ||= load_revision)
  end

  def diff(from, to)
    revs = [from, to].map(&:to_i)
    hs = histories.find(:all, :conditions => ["histories.revision IN (?)", revs],
                              :include => :content)
    from_content, to_content = revs.map{|r| hs.detect{|h| h.revision == r }.content }

    Diff::LCS.sdiff(from_content.data.split(CRLF),
                    to_content.data.split(CRLF)).map(&:to_a)
  end

  def initialize_or_deleted?
    self.revision == 0 or self.deleted?
  end


  private
  def reset_history_caches
    @revision = @new_history = nil
  end

  def load_revision
    histories.maximum(:revision) || 0
  end

end
