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

require 'csv'
class ShareFile < ActiveRecord::Base
  include Publication
  include ValidationsFile
  include Types::ContentType

  attr_accessor :file
  attr_writer :accessed_user

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
    errors.add_to_base _('ご指定の操作は実行できません。') unless updatable?
  end

  def validate_on_create
    return unless valid_presence_of_file file

    valid_extension_of_file file
    valid_content_type_of_file file
    valid_size_of_file file
    valid_max_size_per_owner_of_file file, owner_symbol
    valid_max_size_of_system_of_file file
  end

  def after_save
    Tag.create_by_string category, share_file_tags
  end

  def after_destroy
    File.delete(self.full_path)
  rescue Errno::ENOENT => e
    logger.error e.message
  rescue => e
    e.backtrace.each { |message| logger.error message }
  end

  def symbol_type
    owner_symbol.split(':').first
  end

  def owner_symbol_type
    { 'uid' => 'user', 'gid' => 'group' }[symbol_type]
  end

  def owner_symbol_id
    owner_symbol.split(':').last
  end

  def owner_symbol_name
    owner = Symbol.get_item_by_symbol(self.owner_symbol)
    owner ? owner.name : ''
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
      header = ["アクセス日時", Admin::Setting.login_account, _('user name')]
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
    owner = (symbol_type == User.symbol_type.to_s) ? User.find_by_uid(symbol_id) : Group.find_by_gid(symbol_id)
    File.join(ENV['SHARE_FILE_PATH'], dir_hash[symbol_type], owner.id.to_s)
  end

  def self.total_share_file_size symbol
    sum = 0
    Dir.glob("#{ShareFile.dir_path(symbol)}/**/*").each do |f|
      sum += File.stat(f).size
    end
    sum
  end

  def total_share_file_size
    self.class.total_share_file_size self.owner_symbol
  end

  def file_size
    if File.exist? self.full_path
      File.size self.full_path
    else
      -1
    end
  end

  def file_size_with_unit
    if (size = self.file_size) == -1
      '不明'
    else
      unless (mega_size = size/1.megabyte) == 0
        "#{mega_size}Mbyte"
      else
        unless (kilo_size = size/1.kilobyte) == 0
          "#{kilo_size}Kbyte"
        else
          "#{size}byte"
        end
      end
    end
  end

  def uncheck_authenticity?
    uncheck_extention? && uncheck_content_type?
  end

  def readable?(user = @accessed_user)
    user ? owner_instance(self, user).readable? : false
  end

  def updatable?(user = @accessed_user)
    user ? owner_instance(self, user).updatable? : false
  end

  class Owner
    def initialize(share_file, user)
      @share_file = share_file
      @user = user
    end

    def readable?
      false
    end

    def updatable?
      false
    end
  end

  class UserOwner < Owner
    def readable?
      @user.symbol == @share_file.owner_symbol ? true : publication_range?
    end

    def publication_range?
      if @share_file.protected?
        group_symbols = @user.group_symbols
        return @share_file.publication_symbols_value.split(',').any?{|symbol| @user.symbol == symbol || group_symbols.include?(symbol) }
      end
      @share_file.public?
    end

    def updatable?
      @user.symbol == @share_file.owner_symbol
    end
  end

  class GroupOwner < Owner
    def readable?
      if group = Group.find_by_gid(@share_file.owner_symbol_id)
        participating = group.participating?(@user)
        if participating && (group.administrator?(@user) || @user.id == @share_file.user_id)
          true
        else
          publication_range?(participating)
        end
      else
        false
      end
    end

    def publication_range?(participating = true)
      if @share_file.protected?
        group_symbols = @user.group_symbols
        return @share_file.publication_symbols_value.split(',').any?{|symbol| @user.symbol == symbol || group_symbols.include?(symbol) }
      end
      @share_file.public? || participating
    end

    def updatable?
      if group = Group.find_by_gid(@share_file.owner_symbol_id)
        group.participating?(@user) && (group.administrator?(@user) || @user.id == @share_file.user_id)
      else
        false
      end
    end
  end

private
  def square_brackets_tags
    self.category = Tag.square_brackets_tags(self.category)
  end

  def uncheck_extention?
    CONTENT_TYPE_IMAGES.keys.any?{ |extension| extension.to_s == self.file_name.split('.').last }
  end

  def uncheck_content_type?
    CONTENT_TYPE_IMAGES.values.any?{ |content_types| content_types.split(',').include?(self.content_type) }
  end

  def owner_instance(share_file, user)
    if user_owner?
      UserOwner.new(share_file, user)
    elsif group_owner?
      GroupOwner.new(share_file, user)
    else
      Owner.new(share_file, user)
    end
  end

  def user_owner?
    self.symbol_type == User.symbol_type.to_s
  end

  def group_owner?
    self.symbol_type == Group.symbol_type.to_s
  end
end
