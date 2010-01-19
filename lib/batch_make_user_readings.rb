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

require File.expand_path(File.dirname(__FILE__) + "/batch_base")

class BatchMakeUserReadings < BatchBase

  def self.execute options

    # お知らせ
    BoardEntry.recent(30.minutes).notice.each do |entry|
      entry.publication_users.map{ |user| user.id }.each do |user_id|
        if entry.readable?(User.find_by_id(user_id))
          save_user_reading(user_id, entry)
        end
      end
    end

    # お知らせ以外
    get_updated_entries.each do |entry|
      symbol_type,symbol_id = SkipUtil.split_symbol(entry.symbol)
      user_ids = [] # この記事が更新されたことを通知するuserのid一覧

      # 新着通知に基づく更新
      if owner = entry.load_owner
        Notice.subscribed(owner).each { |notice| user_ids << notice.user_id }
      end

      # 全グループに基づく更新
      if symbol_type == "gid"
        group = Group.active.find(:first,
                                  :conditions => ["gid = ? and group_participations.waiting = 0", symbol_id],
                                  :select => "group_participations.user_id",
                                  :include => :group_participations)
        user_ids += group.group_participations.map { |gr_p| gr_p.user_id }
      end

      # コメントをつけたブログの行く末
      user_ids += BoardEntryComment.find(:all, :conditions => ["board_entry_id = ?", entry.id]).map{ |comment| comment.user_id }
      # ブックマークした記事の行く末
      user_ids += BookmarkComment.find(:all, :conditions => ["bookmarks.url = ?", entry.permalink], :include => [:bookmark]).map{ |comment| comment.user_id }
      # 更新を知らせるユーザ全員に未読レコードを生成
      user_ids.uniq.each do |user_id|
        if entry.readable?(User.find_by_id(user_id))
          save_user_reading(user_id, entry)
        end
      end
    end
  end

  # user_readingに関して更新と新規作成を行う。<br/>
  # 更新処理はupdatable?に該当する場合のみ実施。<br/>
  # 新規作成処理は、最終更新者とアンテナ登録者が異なる場合のみ実施。
  # FIXME モデルに持っていってリファクタしたい。ajaxの未読既読切り替え処理とDRYにする
  def self.save_user_reading antenna_user_id, entry
    last_comment = entry.board_entry_comments.sort{ |a,b| a.updated_on <=> b.updated_on }.last
    if last_comment && last_comment.updated_on > entry.last_updated
      # コメントの最終更新日時が最新
      updater_id = last_comment.user_id
      last_updated_time = last_comment.updated_on
    else
      # 記事自身の最終更新日時が最新
      updater_id = entry.user_id
      last_updated_time = entry.last_updated
    end

    user_reading = UserReading.find_by_user_id_and_board_entry_id(antenna_user_id, entry.id)
    if user_reading
      update_params = {:read => false, :checked_on => nil, :notice_type => nil}
      update_params.merge!(:notice_type => 'notice') if entry.is_notice?
      user_reading.update_attributes(update_params) if updatable?(user_reading, last_updated_time, updater_id, antenna_user_id)
    else
      create_params = {:user_id => antenna_user_id, :board_entry_id => entry.id, :notice_type => nil}
      create_params.merge!(:notice_type => 'notice') if entry.is_notice?
      UserReading.create(create_params) if updater_id != antenna_user_id
    end
  end

  # 以下の条件に該当しない場合のみtrueを返す<br/>
  #  ・更新対象のuser_readingがtrueである<br/>
  #  ・コメント、もしくは記事を書いた人とアンテナの登録者が異なる（自分が書いたコメントはアンテナに反映されない）<br/>
  #  ・コメント、もしくは記事の最終更新日時が、ユーザごとの最終チェック日時以降
  def self.updatable?(user_reading, last_updated_time, updater_id, antenna_user_id)
    user_reading.read and user_reading.checked_on < last_updated_time and updater_id != antenna_user_id
  end

  # 30分以内に記事自身かコメントに更新があったお知らせ以外の記事を全て取得
  def self.get_updated_entries
    BoardEntry.recent_with_comments(30.minutes).aim_type_does_not_equal('notice')
  end
end

BatchMakeUserReadings.execution
