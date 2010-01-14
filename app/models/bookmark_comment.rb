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

class BookmarkComment < ActiveRecord::Base
  belongs_to :bookmark, :counter_cache => true
  belongs_to :user
  has_many :bookmark_comment_tags, :dependent => :destroy
  has_many :tag_strings, :source => :tag,  :through => :bookmark_comment_tags

  N_('BookmarkComment|Public|true')
  N_('BookmarkComment|Public|false')
  N_('BookmarkComment|Stared|true')
  N_('BookmarkComment|Stared|false')

  def validate
    Tag.validate_tags(tags).each{ |error| errors.add(:tags, error) }
  end

  def BookmarkComment.public_types
    [ [_('Publish'), 'true'],      [_('Closed'), 'false'] ]
  end

  def after_save
    Tag.create_by_comma_tags tags, bookmark_comment_tags
  end

  def self.make_conditions_for_tag(login_user_id, options={})
    return make_conditions_tag_or_comment(login_user_id, true, options)
  end

  def self.make_conditions_for_comment(login_user_id, options={})
    return make_conditions_tag_or_comment(login_user_id, false, options)
  end

  def self.get_tag_words(conditions_for_tag = nil)
    options = {}
    options[:order] = 'tags.name'
    options[:include] = [:tag_strings]
    options[:conditions] = conditions_for_tag if conditions_for_tag
    comments = BookmarkComment.find(:all, options)

    categories = []
    comments.each do |comment|
      comment.tag_strings.each do |tag|
        categories << tag.name
      end
    end
    return categories.uniq
  end

  def self.get_tags_hash(login_user_id)
    tags = get_tag_words(["user_id = ?", login_user_id])
    tags_hash = {}
    tags_hash[:standard] = Tag.get_standard_tags
    tags_hash[:mine] = tags - tags_hash[:standard]
    tags_hash[:user] = get_tag_words - (tags + tags_hash[:standard])
    tags_hash
  end

  def self.get_popular_tag_words()
    options = { :select => 'tags.name',
                :joins => 'JOIN tags ON bookmark_comment_tags.tag_id = tags.id',
                :group => 'bookmark_comment_tags.tag_id',
                :order => 'count(bookmark_comment_tags.tag_id) DESC'}

    comment_tags = BookmarkCommentTag.find(:all, options)
    tags = []
    comment_tags.each do |tag|
      tags << tag.name
    end
    return tags.uniq.first(20)
  end

  # 他の人からみた・・・のタグクラウド用タグ一覧を返す
  # TODO まだ数ヶ所残ってるが無くせそうな気がするので見直したい
  def self.get_tagcloud_tags postit_url
    join_state =  "inner join bookmark_comment_tags on bookmark_comment_tags.tag_id = tags.id "
    join_state << "inner join bookmark_comments on bookmark_comments.id = bookmark_comment_tags.bookmark_comment_id "
    join_state << "inner join bookmarks on bookmarks.id = bookmark_comments.bookmark_id "

    Tag.find(:all,
             :select => "tags.name, count(tags.id) as count",
             :conditions => ["bookmarks.url = ? ", postit_url],
             :order => "bookmark_comments.created_on DESC",
             :group => "bookmark_comment_tags.tag_id",
             :joins => join_state)
  end

  def self.get_bookmark_tags
    join_state =  "inner join bookmark_comment_tags on bookmark_comment_tags.tag_id = tags.id "
    join_state << "inner join bookmark_comments on bookmark_comments.id = bookmark_comment_tags.bookmark_comment_id "
    join_state << "inner join bookmarks on bookmarks.id = bookmark_comments.bookmark_id "

    Tag.find(:all,
             :select => "tags.name, count(tags.id) as count",
             :order => "count DESC",
             :group => "bookmark_comment_tags.tag_id",
             :limit => 10,
             :joins => join_state)
  end

  def self.get_tags user_id, limit = nil
    join_state =  "inner join bookmark_comment_tags on bookmark_comment_tags.tag_id = tags.id "
    join_state << "inner join bookmark_comments on bookmark_comments.id = bookmark_comment_tags.bookmark_comment_id "
#    join_state << "inner join bookmarks on bookmarks.id = bookmark_comments.bookmark_id "

    Tag.find(:all,
             :select => "tags.name, count(tags.id) as count",
             :conditions => ["bookmark_comments.user_id = ?", user_id],
             :order => "bookmark_comments.created_on DESC",
             :group => "bookmark_comment_tags.tag_id",
             :limit => limit,
             :joins => join_state)
  end

private
  def self.make_conditions_tag_or_comment(login_user_id, for_tag, options={ })
    condition_state = "user_id = ? "
    condition_param = [options[:user_id]]

    unless login_user_id == options[:user_id]
      condition_state << " and public = 1"
    end

    if options[:keyword]  && !for_tag
      condition_state << " and (bookmarks.title like ? or comment like ?)"
      condition_param << SkipUtil.to_like_query_string(options[:keyword])
      condition_param << SkipUtil.to_like_query_string(options[:keyword])
    end

    if options[:category]  && !for_tag
     condition_state << " and tags like ?"
      condition_param << "%#{options[:category]}%"
    end

    if options[:type] && !for_tag
      if options[:type] == "star"
        condition_state << " and stared = true"
      else
        condition_state << " and bookmarks.url like ?"
        condition_param << Bookmark.get_query_param(options[:type])
      end
    end

    return condition_param.unshift(condition_state)
  end
end
