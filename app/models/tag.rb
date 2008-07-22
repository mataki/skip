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

class Tag < ActiveRecord::Base
  has_many :board_entries, :through => :entry_tags
  has_many :entry_tags

  NOTICE_TAG = '連絡'
  PRIORITY_TAG = '重要'

  def tag
    "[#{name}]"
  end

  def self.get_standard_tags
    self.find_all_by_tag_type("STANDARD").map {|tag| tag.name }
  end

  def self.get_system_tags
    self.find_all_by_tag_type("SYSTEM").map {|tag| tag.name }
  end

  def self.get_system_tag name
    Tag.find(:first, :conditions => ["name = '#{name}'"])
  end

  # 文字列をタグの名前の配列に分解する
  # "[zzz][xxx][yyy]" => ["zzz", "xxx", "yyy"]
  def self.split_tags tags_as_string
    tag_as_array = []
    tags_as_string.split(/\s*\]\s*/).each do |tag_word|
      tag_as_array << tag_word.sub(/\[/, "")
    end
    tag_as_array
  end

  def self.validate_tags tags_as_string
    return [] unless tags_as_string
    errors = []
    tags_as_string.split(',').each do |tag_name|
      if tag_name.split(//u).size > 30
        errors << "ひとつのタグにつき30文字以上入力できません。"
      end
    end

    unless tags_as_string =~ /^(\w|\+|\/|\.|\-|\_|,)*$/
      errors << '使用可能な記号は「+/.-_」及び「,」(タグの区切り)のみです。その他の記号、半角空白は使えません。'
    end

    if tags_as_string.size > 255
      errors << 'は255文字以内で入力してください'
    end

    return errors
  end

  def self.create_by_string tags_as_string, middle_records
    middle_records.clear
    split_tags(tags_as_string).each do |tag_name|
      tag = find_by_name(tag_name) || create(:name => tag_name)
      middle_records.create(:tag_id => tag.id)
    end
  end

  def self.comma_tags tags_as_string
    tags_as_string ? tags_as_string.gsub("][", ",").gsub("[", "").gsub("]", "") : ""
  end

  def self.square_brackets_tags tags_as_string
    tags_as_string ? ("[" + tags_as_string.strip.gsub("[", "").gsub("]", "").gsub(",", "][") + "]").gsub("[]", "") : ""
  end
end
