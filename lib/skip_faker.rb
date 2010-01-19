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

module SkipFaker
  # 指定桁数のランダムな英数字を生成。デフォルトは10桁
  def self.rand_char(digit = 10)
    (0..(digit-1)).map{rand(36).to_s(36)}.join
  end

  # 指定桁数のランダムな数字を生成。デフォルトは10桁
  def self.rand_num(digit = 10)
    (0..(digit-1)).map{rand(10)}.join
  end

  # 指定桁数のランダムな英字を生成。デフォルトは10桁
  def self.rand_alpha(digit = 10)
    (0..(digit-1)).map{(10..35).map{|i| i.to_s(36)}[rand(25)]}.join
  end

  # テスト用の名前を生成
  def self.name
    %w(guchon mat_aki maedana meguro gotanda sinagawa tamati).rand
  end

  # テスト用メールアドレスを生成
  def self.email
    "#{name}#{rand_num}@openskip.org"
  end

  # テスト用のuidを生成
  def self.uid
    "uid:#{name}"
  end

  # テスト用のgidを生成
  def self.gid
    "gid:#{rand_char}"
  end

  # テスト用シンボルを生成
  def self.owner_symbol options = {}
    "#{uid}"
  end

  # テスト用タグ(カテゴリ)を生成
  # タグをfixturesに書き込む場合は""で括らないとyamlのフロースタイルと見なされてしまうので注意
  def self.tag(digit = 10)
    "[#{rand_char(digit -2)}]"
  end

  # テスト用タグ(カテゴリ)を引数で指定した個数生成。デフォルトでは1個
  # タグをfixturesに書き込む場合は""で括らないとyamlのフロースタイルと見なされてしまうので注意
  def self.tags(options = {})
    options[:qt] ||= 1
    options[:digit] ||= 10
    (0..(options[:qt] - 1)).map{tag(options[:digit])}.join
  end

  # テスト用のカンマ区切りタグ(カテゴリ)を引数で指定した個数生成。デフォルトでは1個
  def self.comma_tags(options = {})
    options[:qt] ||= 1
    options[:digit] ? options[:digit] = options[:digit] + 2 : options[:digit] = 10
    convert_comma_tags(tags(options))
  end

  # テスト用標準タグを作成
  # タグをfixturesに書き込む場合は""で括らないとyamlのフロースタイルと見なされてしまうので注意
  def self.standard_tag
    "[#{%w(日記 書評 オフ ネタ ニュース).rand}]"
  end

  # テスト用URL
  def self.url
    "http://"+rand_char+".org"
  end

  def self.today
    Time.now.to_date.to_s
  end

  def self.yesterday
    Time.now.yesterday.to_date.to_s
  end

  def self.tomorrow
    Time.now.tomorrow.to_date.to_s
  end

private
  def self.convert_comma_tags tags
    tags ? tags.gsub("][", ",").gsub("[", "").gsub("]", "") : ""
  end

end
