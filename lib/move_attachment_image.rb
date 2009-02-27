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

class MoveAttachmentImage < BatchBase
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

  # 共有ファイルの実体ファイル配備ディレクトリuidをidに変換
  def self.rename_uid_dir
    user_base_path = "#{INITIAL_SETTINGS['share_file_path']}/user"
    return unless File.exist?(user_base_path)
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

  # 共有ファイルの実体ファイル配備ディレクトリgidをidに変換
  def self.rename_gid_dir
    group_base_path = "#{INITIAL_SETTINGS['share_file_path']}/group"
    return unless File.exist?(group_base_path)
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

  # 記事の添付画像の実体ファイルを共有ファイルのディレクトリへ移動
  # 記事の添付画像に関するデータをshare_filesテーブルに保存
  def self.move_attachment_image
    base_path = "#{INITIAL_SETTINGS['image_path']}/board_entries"
    ShareFile.transaction do
      Dir.foreach(base_path) do |user_dir_name|
        next if (user_dir_name == '.' || user_dir_name == '..')
        user_dir_path = "#{base_path}/#{user_dir_name}"
        Dir.foreach(user_dir_path) do |filename|
          next if (filename == '.' || filename == '..')
          next unless (share_file = new_share_file(user_dir_name, filename))

          # 実ファイルコピー
          src = "#{user_dir_path}/#{filename}"
          dest = share_file.full_path
          FileUtils.cp src, dest

          # DBレコード作成
          share_file.save_without_validation!
        end
      end
    end
  end

  # 記事の本文やコメントの添付画像への直リンクを置換
  def self.replace_direct_link
    BoardEntry.all.each do |board_entry|
      image_link_re = /\/images\/board_entries(\/|%2F)([0-9]+)(\/|%2F)[0-9]+_(.+)/
      board_entry.contents.gsub!(image_link_re) do |matched|
        board_entry = BoardEntry.find_by_id($2.to_i)
        file_name = $4
        replaced_text(board_entry.symbol, file_name) || matched
      end
      board_entry.save!
      board_entry.board_entry_comments.each do |board_entry_comment|
        board_entry_comment.contents.gsub!(image_link_re) do |matched|
          board_entry = BoardEntry.find_by_id($2.to_i)
          file_name = $4
          replaced_text(board_entry.symbol, file_name) || matched
        end
        board_entry_comment.save!
      end
    end
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
    extension = share_file_name.split('.').last.downcase
    share_file = ShareFile.new(
      :file_name => share_file_name,
      :description => '',
      :owner_symbol => owner_symbol,
      :date => Time.now,
      :user_id => created_user_id,
      :content_type =>  "image/#{extension}",
      :publication_type => image_attached_entry.publication_type,
      :publication_symbols_value => image_attached_entry.publication_symbols_value
    )
    image_attached_entry.entry_publications.each do |entry_publication|
      share_file_publication = ShareFilePublication.new(:symbol => entry_publication.symbol)
      share_file.share_file_publications << share_file_publication
    end
    share_file
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
end
