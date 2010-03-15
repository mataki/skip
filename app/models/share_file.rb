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

require 'csv'
class ShareFile < ActiveRecord::Base
  include Publication
  include ::QuotaValidation
  include ::SkipEmbedded::ValidationsFile
  include ::SkipEmbedded::Types::ContentType

  attr_accessor :file

  belongs_to :tenant
  belongs_to :user
  belongs_to :owner, :polymorphic => true
  has_many :tags, :through => :share_file_tags
  has_many :share_file_tags, :dependent => :destroy
  has_many :share_file_accesses, :dependent => :destroy

  validates_length_of   :description, :maximum => 100
  validates_presence_of :file_name
  validates_presence_of :date
  validates_presence_of :user
  validates_presence_of :tenant
  validates_presence_of :owner
  validates_uniqueness_of :file_name, :scope => :owner_id, :message =>_('File with the same name already uploaded.')

  named_scope :owned, proc { |owner|
    { :conditions => ['owner_symbol = ?', owner.symbol] }
  }

  # TODO 回帰テストを書く
  named_scope :accessible, proc { |user|
    if joined_group_ids = Group.active.participating(user).map(&:id) and !joined_group_ids.empty?
      { :conditions => ['share_files.tenant_id = ? AND publication_type = "public" OR owner_id IN (?)', user.tenant_id, joined_group_ids] }
    else
      { :conditions => ['share_files.tenant_id = ? AND publication_type = "public"', user.tenant_id] }
    end
  }

  named_scope :tagged, proc { |tag_words, tag_select|
    return {} unless tag_words
    tag_select = 'AND' unless tag_select == 'OR'
    condition_str = ''
    condition_params = []
    words = tag_words.split(',')
    words.each do |word|
      condition_str << (word == words.last ? ' share_files.category like ?' : " share_files.category like ? #{tag_select}")
      condition_params << SkipUtil.to_like_query_string(word)
    end
    { :conditions => [condition_str, condition_params].flatten }
  }

  def initialize(attr ={})
    super(attr)
    self.publication_type = 'public' if self.publication_type.blank?
  end

  def before_validation_on_create
    if self.file.is_a?(ActionController::UploadedFile)
      self.file_name = file.original_filename
      self.content_type = file.content_type || Types::ContentType::DEFAULT_CONTENT_TYPE
    end
  end

  def validate
    Tag.validate_tags(category).each{ |error| errors.add(:category, error) }
    # errors.add_to_base _('Operation inexecutable.') unless full_accessible?
  end

  def validate_on_create
    return unless valid_presence_of_file file

    valid_extension_of_file file
    valid_content_type_of_file file
    valid_size_of_file file
    valid_max_size_of_system_of_file file
  end

  def after_save
    Tag.create_by_comma_tags category, share_file_tags
  end

  def after_create
    self.upload_file
  end

  def after_destroy
    File.delete(self.full_path)
  rescue Errno::ENOENT => e
    logger.error e.message
  rescue => e
    e.backtrace.each { |message| logger.error message }
  end

  # TODO 回帰テストを書く
  # TODO BoardEntryと統合したい
  def full_accessible? target_user = self.user
    case
    when self.owner_is_user? then self.writer?(target_user)
    when self.owner_is_group? then owner.owned?(target_user) || (owner.joined?(target_user) && self.writer?(target_user))
    else
      false
    end
  end

  # TODO 回帰テストを書く
  # TODO BoardEntryと統合したい
  def accessible? target_user = self.user
    case
    when self.owner_is_user? then self.public? || self.writer(target_user)
    when self.owner_is_group? then self.public? || owner.joind?(target_user)
    else
      false
    end
  end

  # TODO BoardEntryと統合したい
  def accessible_without_writer? target_user = self.user
    !self.writer?(target_user) && self.accessible?(target_user)
  end

  # TODO BoardEntryと統合したい
  def writer? target_user_or_target_user_id
    case
    when target_user_or_target_user_id.is_a?(User) then user_id == target_user_or_target_user_id.id
    when target_user_or_target_user_id.is_a?(Integer) then user_id == target_user_or_target_user_id
    else
      false
    end
  end

  # TODO BoardEntryと統合したい
  # 所属するグループの公開範囲により、共有ファイルの公開範囲を判定する
  def owner_is_public?
    !(owner.is_a?(Group) && owner.protected?)
  end

  # TODO BoardEntryと統合したい
  def owner_is_user?
    owner.is_a?(User)
  end

  # TODO BoardEntryと統合したい
  def owner_is_group?
    owner.is_a?(Group)
  end

#  # TODO owner_symbol_typeのみにしてなくしたい, BoardEntryと統合したい
#  def symbol_type
#    owner_symbol.split(':').first
#  end
#
#  # TODO owner_symbol_idのみにしてなくしたい, BoardEntryと統合したい
#  def symbol_id
#    owner_symbol.split(':')[1]
#  end
#
#  # TODO BoardEntryと統合したい
#  def owner_symbol_type
#    { 'uid' => 'user', 'gid' => 'group' }[symbol_type]
#  end
#
#  # TODO BoardEntryと統合したい
#  def owner_symbol_id
#    owner_symbol.split(':').last
#  end
#
#  # TODO BoardEntryと統合したい
#  def owner_symbol_name
#    owner = Symbol.get_item_by_symbol(self.owner_symbol)
#    owner ? owner.name : ''
#  end
#
#  # TODO BoardEntryと統合したい
#  def owner_id
#    self.class.owner_id owner_symbol
#  end
#
#  # TODO BoardEntryと統合したい
#  def self.owner_id owner_symbol
#    owner(owner_symbol).id
#  end
#
#  # TODO BoardEntryと統合したい
#  def owner
#    self.class.owner owner_symbol
#  end

#  # TODO BoardEntryと統合したい
#  def self.owner owner_symbol
#    symbol_type = owner_symbol.split(":").first
#    symbol_id = owner_symbol.split(":").last
#    owner = (symbol_type == User.symbol_type.to_s) ? User.find_by_uid(symbol_id) : Group.active.find_by_gid(symbol_id)
#  end
#
#
  def self.categories_hash user
    accessible_share_files = ShareFile.accessible(user).descend_by_updated_at
    accessible_share_file_ids = accessible_share_files.map(&:id)
    user_wrote_share_file_ids = accessible_share_files.select {|s| s.user_id == user.id}.map(&:id)

    user_wrote_tags = Tag.uniq_by_share_file_ids(user_wrote_share_file_ids).ascend_by_name.map(&:name)
    recent_user_accessible_tags = Tag.uniq_by_share_file_ids(accessible_share_file_ids[0..9]).ascend_by_name.map(&:name)
    categories_hash = {}
    categories_hash[:mine] = user_wrote_tags
    categories_hash[:user] = recent_user_accessible_tags - user_wrote_tags
    categories_hash
  end

  # TODO Tagのnamed_scopeにしてなくしたい
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

#  def visibility
#    text = color = ""
#    if public?
#      text = _("[Open to all]")
#      color = "yellow"
#    elsif private?
#      if owner_symbol.include?("uid")
#        text = _("[Owner only]")
#      else
#        text = _("[Group members only]")
#      end
#      color = "#FFDD75"
#    end
#
#    if text == ""
#      text = "[#{publication_symbols_value}]"
#      color = "#FFCD35"
#    end
#    return text, color
#  end
#
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
      header = [_("Date Accessed"), Admin::Setting.login_account, _('user name')]
      header.map! {|col| NKF.nkf('-sZ', col) }
      csv << header
      share_file_accesses.each do |access|
        csv << [access.created_at.strftime("%Y/%m/%d %H:%M"), access.user.email, NKF.nkf('-sZ', access.user.name)]
      end
    end
    return buf, (file_name.gsub(/\./, '_') + '_history.csv')
  end

  def upload_file src_file = self.file
    open(full_path, "w+b") { |f| f.write(src_file.read) }
  end

  def full_path
    FileUtils.mkdir_p self.dir_path
    File.join(self.dir_path, self.file_name)
  end

  def dir_path
    File.join(SkipEmbedded::InitialSettings['share_file_path'], tenant.id.to_s, owner_type.downcase, owner_id.to_s)
  end
#
#  def self.total_share_file_size symbol
#    sum = 0
#    Dir.glob("#{ShareFile.dir_path(symbol)}/**/*").each do |f|
#      sum += File.stat(f).size
#    end
#    sum
#  end
#
#  def total_share_file_size
#    self.class.total_share_file_size self.owner_symbol
#  end
#
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
#
#  def image_extention?
#    CONTENT_TYPE_IMAGES.keys.any?{ |extension| extension.to_s.downcase == extname }
#  end
#
  def extname
    File.extname(file_name).sub(/\A\./,'').downcase
  end

  private
  def uncheck_extention?
    uncheck_extentions = CONTENT_TYPE_IMAGES.keys << :swf << :flv
    uncheck_extentions.any?{ |extension| extension.to_s.downcase == extname }
  end

  def uncheck_content_type?
    uncheck_content_types = CONTENT_TYPE_IMAGES.values << 'application/x-shockwave-flash' << 'video/x-flv'
    uncheck_content_types.any?{ |content_types| content_types.split(',').include?(self.content_type) }
  end
end
