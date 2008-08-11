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

class BatchMakeUserReadings < BatchBase

  def self.execute options
    get_updated_entries.each do |entry|
      symbol_type,symbol_id = SkipUtil.split_symbol(entry.symbol)
      user_ids = [] # このエントリが更新されたことを通知するuserのid一覧

      # アンテナに基づく更新
      antenna_items = AntennaItem.find(:all,
                                       :conditions => ["value_type = ? and value = ?", "symbol", entry.symbol],
                                       :include => :antenna)
      antenna_items.each{ |antenna_item| user_ids << antenna_item.antenna.user_id }

      # 全グループに基づく更新
      if symbol_type == "gid"
        group = Group.find(:first,
                           :conditions => ["gid = ? and group_participations.waiting = 0", symbol_id],
                           :select => "group_participations.user_id",
                           :include => :group_participations)
        user_ids += group.group_participations.map { |gr_p| gr_p.user_id }
      end

      # コメントをつけたブログの行く末
      user_ids += BoardEntryComment.find(:all, :conditions => ["board_entry_id = ?", entry.id]).map{ |comment| comment.user_id }
      # ブックマークしたエントリの行く末
      user_ids += BookmarkComment.find(:all, :conditions => ["bookmarks.url = ?", entry.permalink], :include => [:bookmark]).map{ |comment| comment.user_id }
      # あなたへの連絡
      user_ids += contact_ids entry
      # 更新を知らせるユーザ全員に未読レコードを生成
      user_ids.uniq.each { |user_id| save_user_reading(user_id, entry) if viewable?(user_id, entry.entry_publications) }
    end
  end

  # user_readingに関して更新と新規作成を行う。<br/>
  # 更新処理はupdatable?に該当する場合のみ実施。<br/>
  # 新規作成処理は、最終更新者とアンテナ登録者が異なる場合のみ実施。
  def self.save_user_reading antenna_user_id, entry
    last_comment = entry.board_entry_comments.sort{ |a,b| a.updated_on <=> b.updated_on }.last
    if last_comment && last_comment.updated_on > entry.last_updated
      # コメントの最終更新日時が最新
      updater_id = last_comment.user_id
      last_updated_time = last_comment.updated_on
    else
      # エントリ自身の最終更新日時が最新
      updater_id = entry.user_id
      last_updated_time = entry.last_updated
    end

    user_reading = UserReading.find_by_user_id_and_board_entry_id(antenna_user_id, entry.id)
    if user_reading
      user_reading.update_attributes({:read => false, :checked_on => nil}) if updatable?(user_reading, last_updated_time, updater_id, antenna_user_id)
    else
      UserReading.create(:user_id => antenna_user_id, :board_entry_id => entry.id) if updater_id != antenna_user_id
    end
  end

  # 以下の条件に該当しない場合のみtrueを返す<br/>
  #  ・更新対象のuser_readingがtrueである<br/>
  #  ・コメント、もしくはエントリを書いた人とアンテナの登録者が異なる（自分が書いたコメントはアンテナに反映されない）<br/>
  #  ・コメント、もしくはエントリの最終更新日時が、ユーザごとの最終チェック日時以降
  def self.updatable?(user_reading, last_updated_time, updater_id, antenna_user_id)
    user_reading.read and user_reading.checked_on < last_updated_time and updater_id != antenna_user_id
  end

  # todo viewableの高速化 => viable_symbolsとuserをキャッシュしておく
  def self.viewable?(user_id, publications)
    user = User.find(user_id)
    viewable_symbols = ["sid:allusers", user.symbol]
    viewable_symbols += GroupParticipation.get_gid_array_by_user_id(user_id)

    for publication in publications
      return true if viewable_symbols.include?(publication.symbol)
    end

    return false
  end

  # [連絡]タグが指定されている場合、連絡先のユーザのID一覧を返す
  def self.contact_ids entry
    return [] unless entry.category.include?("[#{Tag::NOTICE_TAG}]")
    entry.publication_users.map{ |user| user.id }
  end

  # 30分以内にエントリ自身かコメントに更新があったエントリを全て取得
  def self.get_updated_entries
    conditions_state =  "(last_updated BETWEEN subtime(now(), '00:30:00') AND now())"
    conditions_state << " OR "
    conditions_state << "(board_entry_comments.updated_on BETWEEN subtime(now(), '00:30:00') AND now())"

    BoardEntry.find(:all,
                    :conditions => conditions_state,
                    :select => "board_entries.id, symbol, board_entry_comments.user_id",
                    :include => [:board_entry_comments, :entry_publications])
  end

end

BatchMakeUserReadings.execution
