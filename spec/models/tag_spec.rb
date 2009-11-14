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

require File.dirname(__FILE__) + '/../spec_helper'

describe Tag do
  fixtures :tags, :board_entries, :share_files, :bookmark_comments

  # FIXME テスト汎用化。Fakerを使った形に出来ないか？
  STANDARD_TAG_NAMES = ["日記", "書評", "オフ", "ネタ", "ニュース"]
  def test_tag
    assert_not_nil @a_tag.tag
  end

  def test_get_standard_tags
    Tag.get_standard_tags.each{ |tagname| assert(STANDARD_TAG_NAMES.include?(tagname)) }
  end

  def test_split_tags
    assert "[hoge]", Tag.split_tags("hoge")
    assert "[hoge]]", Tag.split_tags("hoge]")
    assert "[]", Tag.split_tags("")
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

describe Tag, 'validate_tags' do
  describe '正常なタグの場合' do
    it { Tag.validate_tags(SkipFaker.comma_tags).size.should == 0 }
  end

  describe '許容する記号の場合' do
    it { Tag.validate_tags("あああ.いい").size.should == 0 }
    it { Tag.validate_tags("あ+ああ/い-_.い").size.should == 0 }
    it { Tag.validate_tags("あ ああ/い-_.い").size.should == 0 }
  end

  describe '許容しない記号の場合' do
    it { Tag.validate_tags("ああ*あ=いい").size.should == 1 }
  end

  describe 'ひとつのタグの長さが30文字の場合' do
    it { Tag.validate_tags(SkipFaker.comma_tags(:digit => 30)).size.should == 0 }
    it { Tag.validate_tags(two_byte_tag(:digit => 30)).size.should == 0 }
  end

  describe 'ひとつのタグの長さが31文字の場合' do
    it { Tag.validate_tags(SkipFaker.comma_tags(:digit => 31)).size.should == 1 }
    it { Tag.validate_tags(two_byte_tag(:digit => 31)).size.should == 1 }
  end

  describe 'ひとつのタグの長さが29文字で全長が255文字の場合' do
    it { Tag.validate_tags(SkipFaker.comma_tags(:digit => 29, :qt => 8 ) + ',' + SkipFaker.comma_tags(:digit => 15)).size.should == 0 }
    it { Tag.validate_tags(two_byte_tag(:digit => 29 , :qt => 8) + ',' + two_byte_tag(:digit => 15)).size.should == 0 }
  end

  describe 'ひとつのタグの長さが29文字で全長が256文字の場合' do
    it { Tag.validate_tags(SkipFaker.comma_tags(:digit => 29, :qt => 8 ) + ',' + SkipFaker.comma_tags(:digit => 16)).size.should == 1 }
    it { Tag.validate_tags(two_byte_tag(:digit => 29 , :qt => 8) + ',' + two_byte_tag(:digit => 16)).size.should == 1 }
  end

  describe '複合エラーの場合' do
    it { Tag.validate_tags(SkipFaker.comma_tags(:digit => 31)+ "[aaaa=*]").size.should == 2 }
  end

  def two_byte_tag(options = {})
    options[:qt] ||= 1
    options[:digit] ? options[:digit] = options[:digit] : options[:digit] = 10
    array = []
    str = ''
    (1..options[:digit]).each do
      str += 'あ'
    end
    (1..options[:qt]).each do
      array << str
    end
    array.join(',')
  end
end

describe Tag, 'square_brackets_tags' do
  it '文字列前方の空白文字列が取り除かれること' do
    Tag.square_brackets_tags(' foo,bar').should == '[foo][bar]'
  end
  it '文字列後方の空白文字列が取り除かれること' do
    Tag.square_brackets_tags('foo,bar ').should == '[foo][bar]'
  end
  it 'カンマ前方の空白文字列が取り除かれること' do
    Tag.square_brackets_tags('foo ,bar').should == '[foo][bar]'
  end
  it 'カンマ後方の空白文字列が取り除かれること' do
    Tag.square_brackets_tags('foo, bar').should == '[foo][bar]'
  end
  it 'タグ文字列中の空白文字列は取り除かれないこと' do
    Tag.square_brackets_tags('f oo,bar').should == '[f oo][bar]'
  end
  it 'タグ文字列中の[は取り除かれること' do
    Tag.square_brackets_tags('f[oo,bar').should == '[foo][bar]'
  end
  it 'タグ文字列中の]は取り除かれること' do
    Tag.square_brackets_tags('f]oo,bar').should == '[foo][bar]'
  end
  it 'タグ文字列中の[]は取り除かれること' do
    Tag.square_brackets_tags('f[]oo,bar').should == '[foo][bar]'
  end
  it 'nilの時は空文字となること' do
    Tag.square_brackets_tags(nil).should == ''
  end
  it '既に変換済みの場合は同じ文字列になること' do
    Tag.square_brackets_tags('[foo][bar]').should == '[foo][bar]'
  end
end

