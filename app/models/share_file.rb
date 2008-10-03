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

require 'csv'
class ShareFile < ActiveRecord::Base
  belongs_to :user
  has_many :tags, :through => :share_file_tags
  has_many :share_file_tags, :dependent => :destroy
  has_many :share_file_publications, :dependent => :destroy
  has_many :share_file_accesses, :dependent => :destroy

  before_save :square_brackets_tags

  validates_length_of   :description, :maximum=>100, :message =>'は100桁以内で入力してください'
  validates_presence_of :file_name, :message =>'は必須です'
  validates_presence_of :date, :message =>'は必須です'
  validates_presence_of :user_id, :message =>'は必須です'
  validates_uniqueness_of :file_name, :scope => :owner_symbol, :message =>'名が同一のファイルが既に登録されています'

  class << self
    HUMANIZED_ATTRIBUTE_KEY_NAMES = {
      "description" => "コメント",
      "category" => "タグ",
      "date" => "日付",
      "file_name" => "ファイル"
    }
    def human_attribute_name(attribute_key_name)
      HUMANIZED_ATTRIBUTE_KEY_NAMES[attribute_key_name] || super
    end
  end

  def validate
    Tag.validate_tags(category).each{ |error| errors.add(:category, error) }
  end

  def after_save
    Tag.create_by_string category, share_file_tags
  end

  def owner_symbol_type
    symbol_type = owner_symbol.split(':').first
    { 'uid' => 'user', 'gid' => 'group' }[symbol_type]
  end

  def owner_symbol_id
    owner_symbol.split(':').last
  end

  # 全公開かどうか
  def public?
    publication_type == 'public'
  end

  # 自分のみ、参加者のみかどうか
  def private?
    publication_type == 'private'
  end

  # 直接指定かどうか
  def protected?
    publication_type == 'protected'
  end

  # 所属するグループの公開範囲により、共有ファイルの公開範囲を判定する
  def owner_is_public?
    Symbol.public_symbol_obj? owner_symbol
  end

  # 共有ファイル一覧のタグ用
  def self.get_tags(owner_symbol)
    ShareFileTag.find(:all,
                      :include => [ :share_file, :tag ] ,
                      :conditions => ["share_files.owner_symbol = ?", owner_symbol]).map{ |tag| tag.tag.name }.uniq
  end

  def self.get_tags_hash(owner_symbol = nil)
    # TODO:サブクエリを使うようにしないとアクセス数とデータ数が多くなる

    options = { :conditions => ["owner_symbol = ?", owner_symbol]} if owner_symbol
    share_files = ShareFile.find(:all, options).map {|share_file| share_file.id}

    owner_tag_names = []
    popular_tag_names = []
    if share_files.size > 0
      options = { :select => 'tags.name',
                  :joins => 'JOIN tags ON share_file_tags.tag_id = tags.id',
                  :group => 'share_file_tags.tag_id',
                  :order => 'count(share_file_tags.tag_id) DESC',
                  :conditions => ["share_file_tags.share_file_id in (?)", share_files]}

      owner_tag_names = ShareFileTag.find(:all, options).map {|tag| tag.name }

      options[:conditions] = ["share_file_tags.share_file_id not in (?)", share_files]
      popular_tag_names = owner_symbol ? ShareFileTag.find(:all, options).map {|tag| tag.name } : owner_tag_names # ownerが指定されてないなら同一となる

    end
    { :mine => owner_tag_names, :user => (popular_tag_names-owner_tag_names).first(10), :popular => popular_tag_names.first(10) }
  end

  def self.get_popular_tag_words()
    options = { :select => 'tags.name',
                :joins => 'JOIN tags ON share_file_tags.tag_id = tags.id',
                :group => 'share_file_tags.tag_id',
                :order => 'count(share_file_tags.tag_id) DESC'}

    comment_tags = ShareFileTag.find(:all, options)
    tags = []
    comment_tags.each do |tag|
      tags << tag.name
    end
    return tags.uniq.first(40)
  end

 # 検索条件の生成、可視（編集）可能なsymbolを返却
  def self.make_conditions(login_user_symbols, options={})
    options.assert_valid_keys [:keyword, :id, :category, :tag_words, :tag_select, :recent_day, :owner_symbol, :file_name, :without_public]

    conditions_param = []

    # 公開条件（必須）
    viewable_symbols = [] + login_user_symbols
    viewable_symbols << Symbol::SYSTEM_ALL_USER unless options[:without_public] # 全公開は見れる

    conditions_state = "(share_file_publications.symbol in (?))"
    conditions_param << viewable_symbols

    # 所有者のファイルのみを条件にする
    if symbol = options[:owner_symbol]
      conditions_state << " and share_files.owner_symbol = ? "
      conditions_param << symbol
    end

    # キーワード条件
    if keyword = options[:keyword]
      conditions_state << " and (share_files.file_name like ? or share_files.description like ?)"
      conditions_param << SkipUtil.to_like_query_string(keyword)
      conditions_param << SkipUtil.to_like_query_string(keyword)
    end

    # ファイル名条件
    if file_name = options[:file_name]
      conditions_state << " and share_files.file_name = ?"
      conditions_param << file_name
    end

    # id条件（一意）
    if id = options[:id]
      conditions_state << " and share_files.id = ?"
      conditions_param << id
    end

    # カテゴリ
    if category = options[:category] and category != ''
      conditions_state << " and share_files.category like ?"
      conditions_param << '%[' + category + ']%'
    end

    #タグ
    if options[:tag_words] && options[:tag_select]
      words = options[:tag_words].split(',')
      if options[:tag_select] == "AND"
        words.each do |word|
          conditions_state << " and share_files.category like ?"
          conditions_param << SkipUtil.to_like_query_string(word)
        end
      else
        words.each do |word|
          conditions_state << " and (" if word == words.first
          conditions_state << " share_files.category like ? OR" if word != words.last
          conditions_state << " share_files.category like ?)" if word == words.last
          conditions_param << SkipUtil.to_like_query_string(word)
        end
      end
    end

    # 最近の何日間条件
    if recent_day = options[:recent_day]
      conditions_state << " and share_files.date >  ?"
      conditions_param << Date.today-recent_day
    end

    return { :conditions => conditions_param.unshift(conditions_state), :include => [:share_file_publications]}
  end

  def visibility
    text = color = ""
    if public?
      text = "[全体に公開]"
      color = "yellow"
    elsif private?
      if owner_symbol.include?("uid")
        text = "[自分だけ]"
      else
        text = "[参加者のみ]"
      end
      color = "#FFDD75"
    end

    if text == ""
      text = "[#{publication_symbols_value}]"
      color = "#FFCD35"
    end
    return text, color
  end

  def create_history login_user_id
    ShareFile.increment_counter("total_count", id)
    ShareFileAccess.create(:share_file_id => id,
                           :user_id => login_user_id)
  end

  def get_accesses_as_csv
    share_file_accesses = ShareFileAccess.find(:all,
                                               :order => "created_at DESC",
                                               :conditions => ["share_file_id = ?", id],
                                               :include => :user)
    buf = ""
    CSV::Writer.generate(buf) do |csv|
      header = ["アクセス日時", CUSTOM_RITERAL[:login_account], "ユーザ名"]
      header.map! {|col| NKF.nkf('-sZ', col) }
      csv << header
      share_file_accesses.each do |access|
        csv << [access.created_at.strftime("%Y/%m/%d %H:%M"), access.user.code, NKF.nkf('-sZ', access.user.name)]
      end
    end
    return buf, (file_name.gsub(/\./, '_') + '_history.csv')
  end

  def comma_category
    Tag.comma_tags(self.category)
  end

  def upload_file src_file
    open(full_path, "w+b") { |f| f.write(src_file.read) }
  end

  def full_path
    target_dir_path = ShareFile.dir_path(self.owner_symbol)
    FileUtils.mkdir_p target_dir_path
    File.join(target_dir_path, self.file_name)
  end

  def self.dir_path owner_symbol
    dir_hash = { 'uid' => 'user',
                 'gid' => 'group' }
    symbol_type = owner_symbol.split(":").first
    symbol_id = owner_symbol.split(":").last
    File.join(ENV['SHARE_FILE_PATH'], dir_hash[symbol_type], symbol_id)
  end

private
  def square_brackets_tags
    self.category = Tag.square_brackets_tags(self.category)
  end

end
