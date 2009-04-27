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

require 'kconv'
require 'uri'
require 'open-uri'

class Bookmark < ActiveRecord::Base
  has_many :bookmark_comments, :dependent => :destroy
  has_many :popular_bookmarks, :dependent => :destroy

  validates_presence_of :url, :message =>'は必須です'
  validates_length_of :url, :maximum=>255, :message =>'は255文字以内で入力してください'
  validates_format_of :url, :message =>'はhttp://...の形式で入力してください(httpsも可)', :with => URI.regexp, :if => :is_type_internet?
  validates_presence_of :title, :message =>'は必須です'
  validates_length_of :title, :maximum=>255, :message =>'は255文字以内で入力してください'

  SORT_TYPES = [["登録日順(降順)","bookmarks.updated_on DESC"],["登録日順(昇順)","bookmarks.updated_on"],["ユーザ数順","bookmark_comments_count DESC"]].freeze
  class << self
    HUMANIZED_ATTRIBUTE_KEY_NAMES = {
      "url" => "URL",
      "title" => "タイトル",
    }
    def human_attribute_name(attribute_key_name)
      HUMANIZED_ATTRIBUTE_KEY_NAMES[attribute_key_name] || super
    end
  end

  class InvalidMultiByteURIError < RuntimeError;end

  def self.get_title_from_url url
    begin
      open(url, :proxy => INITIAL_SETTINGS['proxy_url']) do |f|
        re = /<(title|TITLE)>(.*?)<\/(title|TITLE)>/
        f.each_line do |line|
          return $2.toutf8 if re.match(line)
        end
      end
    rescue Exception => ex
      ex.backtrace.each {  |message| logger.error message }
    end
    return ""
  end

  def self.make_conditions(options={ })
    condition_param = []
    condition_state = "bookmark_comments_count > 0 AND bookmark_comments.public = true "

    if options[:title]
      condition_state << " and title like ?"
      condition_param << SkipUtil.to_like_query_string(options[:title])
    end

    if options[:tag_words] && options[:tag_select]
      words = options[:tag_words].split(',')
      if options[:tag_select] == "AND"
        words.each do |word|
          condition_state << " and bookmark_comments.tags like ?"
          condition_param << SkipUtil.to_like_query_string(word)
        end
      else
        words.each do |word|
          condition_state << " and (" if word == words.first
          condition_state << " bookmark_comments.tags like ? OR" if word != words.last
          condition_state << " bookmark_comments.tags like ?)" if word == words.last
          condition_param << SkipUtil.to_like_query_string(word)
        end
      end
    end

    if options[:type] and options[:type] != 'all'
     condition_state << " and url like ?"
     condition_param << Bookmark.get_query_param(options[:type])
    end

    return condition_param.unshift(condition_state)
  end

  def is_type_page?
    self.url.index("/page/") == 0
  end

  def is_type_user?
    self.url.index("/user/") == 0
  end

  def is_type_internet?
    !(is_type_page?) and !(is_type_user?)
  end

  def escaped_url
    URI.unescape(url).unpack('U*')
    URI.escape(URI.escape(url), "'")
  rescue ArgumentError => e
    self.url = 'invalid_url'
  end

  def self.unescaped_url url
    returning u = URI.unescape(url) do
      u.unpack('U*')
    end
  rescue ArgumentError => e
    raise Bookmark::InvalidMultiByteURIError.new(e.message)
  end

  def title
    URI.unescape(url).unpack('U*')
    read_attribute(:title)
  rescue ArgumentError => e
    write_attribute(:title, _('invalid url'))
  end

  # ブックマークされたURLが全公開であるか
  # 全公開でない記事のときfalse
  def url_is_public?
    return true unless is_type_page?

    entry_id = url.split('/')[2]
    entry = BoardEntry.find_by_id(entry_id)
    return entry.public?
  end

  def self.get_query_param bookmark_type
    case bookmark_type
    when "user"
      "/user/%"
    when "page"
      "/page/%"
    when "internet"
      "http%"
    end
  end

  def tags_as_string
    tags = []
    bookmark_comments.each do |comment|
      tags.concat(Tag.split_tags(comment.tags))
    end
    tag_str =  tags.uniq.join('][')
    return tags.size > 0 ? "[#{tag_str}]" :""
  end

  def self.find_visible(limit = 5, recent_day = 10)
    find(:all,
         :select => 'distinct bookmarks.*',
         :include => 'bookmark_comments',
         :conditions => ["bookmarks.updated_on > ? AND bookmark_comments.public = ? ", Date.today - recent_day, true],
         :limit => limit,
         :order =>"bookmarks.updated_on DESC" )
  end
end
