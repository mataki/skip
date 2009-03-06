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
require File.expand_path(File.dirname(__FILE__) + "/../config/environment")

class MoveAttachmentImage
  @@logger = ActiveRecord::Base.logger

  def self.execute options = {}
    # 共有ファイルのディレクトリリネーム
    log_info('start rename uid directory ...')
    rename_uid_dir
    log_info('end rename uid directory')

    log_info('start rename gid directory ...')
    rename_gid_dir
    log_info('end rename gid directory')

    if INITIAL_SETTINGS['image_path'] && File.exist?(INITIAL_SETTINGS['image_path'])
      # 記事の添付画像の移行
      log_info('start move attachment image ...')
      move_attachment_image
      log_info('end move attachment image ...')

      # 記事内の添付画像への直リンクを置換
      log_info('start replace attachment link ...')
      replace_direct_link
      log_info('end replace attachment link ...')
    end
  end

  # ユーザの共有ファイルのパスを取得
  # 取得できない場合はnilが返る
  def self.user_share_file_path
    share_file_path = INITIAL_SETTINGS['share_file_path']
    if share_file_path && File.exist?(share_file_path)
      share_file_user_path = "#{share_file_path}/user"
      File.exist?(share_file_user_path) ? share_file_user_path : nil
    else
      nil
    end
  end

  # ユーザ所有の共有ファイルの実体ファイル配備ディレクトリ名に使われているuidをidに変換
  def self.rename_uid_dir
    if user_base_path = user_share_file_path
      Dir.foreach(user_base_path) do |uid|
        next if (uid == '.' || uid == '..')
        src = "#{user_base_path}/#{uid}"
        if user = User.find_by_uid(uid)
          dest = "#{user_base_path}/#{user.id}"
          FileUtils.mv src, dest
          log_info("Success rename directory name from #{src} to #{dest}.")
        else
          log_warn("Failure rename directory(#{src}). Because user is not found that uid is #{uid}")
        end
      end
    end
  end

  # グループの共有ファイルのパスを取得
  # 取得できない場合はnilが返る
  def self.group_share_file_path
    share_file_path = INITIAL_SETTINGS['share_file_path']
    if share_file_path && File.exist?(share_file_path)
      share_file_group_path = "#{share_file_path}/group"
      File.exist?(share_file_group_path) ? share_file_group_path : nil
    else
      nil
    end
  end

  # グループ所有の共有ファイルの実体ファイル配備ディレクトリ名に使われているgidをidに変換
  def self.rename_gid_dir
    if group_base_path = group_share_file_path
      Dir.foreach(group_base_path) do |gid|
        next if (gid == '.' || gid == '..')
        if group = Group.find_by_gid(gid)
          src = "#{group_base_path}/#{gid}"
          dest = "#{group_base_path}/#{group.id}"
          FileUtils.mv src, dest
          log_info("Success rename directory name from #{src} to #{dest}.")
        else
          log_warn("Failure rename directory name from #{src} to #{dest}. Because group is not found that gid is #{gid}")
        end
      end
    end
  end

  def self.entry_image_base_path
    base_path = "#{INITIAL_SETTINGS['image_path']}/board_entries"
    File.exist?(base_path) ? base_path : nil
  end

  # 記事の添付画像の実体ファイルを共有ファイルのディレクトリへ移動
  # 記事の添付画像に関するデータをshare_filesテーブルに保存
  def self.move_attachment_image
    if base_path = entry_image_base_path
      ShareFile.transaction do
        Dir.foreach(base_path) do |user_dir_name|
          next if (user_dir_name == '.' || user_dir_name == '..')
          user_dir_path = "#{base_path}/#{user_dir_name}"
          Dir.foreach(user_dir_path) do |filename|
            next if (filename == '.' || filename == '..')
            next unless (share_file = new_share_file(user_dir_name, filename))

            # 実ファイル移動
            src = "#{user_dir_path}/#{filename}"
            dest = share_file.full_path
            FileUtils.mv src, dest

            # DBレコード作成
            share_file.save_without_validation!
          end
        end
      end
    end
  end

  # 記事の本文やコメントの添付画像への直リンクを置換
  def self.replace_direct_link
    BoardEntry.all.each do |board_entry|
      replace_entry_direct_link board_entry
      board_entry.board_entry_comments.each do |board_entry_comment|
        replace_entry_comment_direct_link board_entry_comment
      end
    end
  end

  def self.replace_entry_direct_link entry
    entry.contents_will_change!
    entry.contents.gsub!(image_link_re) do |matched|
      matched_entry = BoardEntry.find_by_id($3.to_i)
      file_name = $4
      replaced_text(matched_entry.symbol, file_name) || matched
    end
    entry.save_without_validation!
  end

  def self.replace_entry_comment_direct_link entry_comment
    entry_comment.contents_will_change!
    entry_comment.contents.gsub!(image_link_re) do |matched|
      matched_entry = BoardEntry.find_by_id($3.to_i)
      file_name = $4
      replaced_text(matched_entry.symbol, file_name) || matched
    end
    entry_comment.save_without_validation!
  end

  def self.image_link_re
    /\/images\/board_entries(\/|%2F)[0-9]+(\/|%2F)([0-9]+)_([^\r\n]+)/
  end

  # 置換成功時は置換したテキスト、失敗時はnilを返す
  def self.replaced_text symbol, file_name
    type = symbol.split(':').first
    value = symbol.split(':').last
    if type == 'uid'
      return nil unless user = User.find_by_uid(value)
      "/share_file/user/#{user.id}/#{file_name}"
    elsif type == 'gid'
      return nil unless group = Group.find_by_gid(value)
      "/share_file/group/#{group.id}/#{file_name}"
    else
      nil
    end
  end

  def self.new_share_file created_user_id, image_file_name
    return unless(image_attached_entry = image_attached_entry(image_file_name))
    owner_symbol = image_attached_entry.symbol
    share_file_name = share_file_name(owner_symbol, image_file_name)
    share_file = ShareFile.new(
      :file_name => share_file_name,
      :description => '',
      :owner_symbol => owner_symbol,
      :date => Time.now,
      :user_id => created_user_id,
      :publication_type => image_attached_entry.publication_type,
      :publication_symbols_value => image_attached_entry.publication_symbols_value
    )
    share_file.content_type = content_type(share_file)
    image_attached_entry.entry_publications.each do |entry_publication|
      share_file_publication = ShareFilePublication.new(:symbol => entry_publication.symbol)
      share_file.share_file_publications << share_file_publication
    end
    share_file
  end

  def self.content_type share_file
    extension = share_file.file_name.split('.').last.downcase
    if share_file.image_extention?
      "image/#{extension}"
    else
      "application/octet-stream"
    end
  end

  def self.share_file_name owner_symbol, image_file_name
    share_file_name = image_file_name.split('_', 2).last
    # 同名ファイル対策
    while ShareFile.find_by_owner_symbol_and_file_name(owner_symbol, share_file_name) do
      share_file_name = "#{File::basename(share_file_name, '.*')}_#{File::extname(share_file_name)}"
    end
    share_file_name
  end

  def self.image_attached_entry image_file_name
    BoardEntry.find_by_id(image_file_name.split('_', 2).first.to_i)
  end

  def self.log_info message
    @@logger.info message
  end

  def self.log_warn message
    @@logger.warn message
  end
end
