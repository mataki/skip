# SKIP(Social Knowledge & Innovation Platform)
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

require File.dirname(__FILE__) + '/../spec_helper'

describe Tag do
  fixtures :tags, :board_entries, :share_files, :bookmark_comments

  # FIXME テスト汎用化。Fakerを使った形に出来ないか？
  SYSTEM_TAG_NAMES = ["質問", "要望", "重要", "連絡", "解決"]
  STANDARD_TAG_NAMES = ["書評", "もんた", "日記", "技術", "ネタ", "ニュース"]
  def test_tag
    assert_not_nil @a_tag.tag
  end

  def test_get_standard_tags
    Tag.get_standard_tags.each{ |tagname| assert(STANDARD_TAG_NAMES.include?(tagname)) }
  end

  def test_get_system_tags
    Tag.get_system_tags.each{ |tagname| assert(SYSTEM_TAG_NAMES.include?(tagname)) }
  end

  def test_get_system_tag
    assert_equal '[連絡]', Tag.get_system_tag(Tag::NOTICE_TAG).tag
  end

  def test_split_tags
    assert "[hoge]", Tag.split_tags("hoge")
    assert "[hoge]]", Tag.split_tags("hoge]")
    assert "[]", Tag.split_tags("")
  end

  def test_validate_tags
    assert_equal Tag.validate_tags(SkipFaker.comma_tags).size, 0

    assert_equal Tag.validate_tags("あああ.いい").size, 0
    assert_equal Tag.validate_tags("あ+ああ/い-_.い").size, 0

    assert_equal Tag.validate_tags("ああ*あ=いい").size, 1

    assert_equal Tag.validate_tags(SkipFaker.comma_tags(:digit => 30)).size, 0
    assert_equal Tag.validate_tags(SkipFaker.comma_tags(:digit => 31)).size, 1

    assert_equal Tag.validate_tags(SkipFaker.comma_tags(:digit => 29, :qt => 8 ) + ',' + SkipFaker.comma_tags(:digit => 15)).size, 0
    assert_equal Tag.validate_tags(SkipFaker.comma_tags(:digit => 29, :qt => 8 ) + ',' + SkipFaker.comma_tags(:digit => 16)).size, 1

    assert_equal Tag.validate_tags(SkipFaker.comma_tags(:digit => 31)+ "[aaaa=*]").size, 2
  end

  def test_create_by_string
    @a_entry.category = ''
    Tag.create_by_string @a_entry.category, @a_entry.entry_tags
    assert_equal @a_entry.entry_tags.size, 0

    @a_entry.category = SkipFaker.tags :qt => 2
    Tag.create_by_string @a_entry.category, @a_entry.entry_tags
    assert_equal @a_entry.entry_tags.size, 2

    @a_share_file.category = SkipFaker.tags :qt => 3
    Tag.create_by_string @a_share_file.category, @a_share_file.share_file_tags
    assert_equal @a_share_file.share_file_tags.size, 3

    @a_bookmark_comment.tags = SkipFaker.tags :qt => 4
    Tag.create_by_string @a_bookmark_comment.tags, @a_bookmark_comment.bookmark_comment_tags
    assert_equal @a_bookmark_comment.bookmark_comment_tags.size, 4
  end
end
