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

require File.dirname(__FILE__) + '/../spec_helper'
require File.dirname(__FILE__) + '/../../lib/batch_make_user_readings'

describe BatchMakeUserReadings do
  fixtures :users, :board_entries, :groups, :user_uids

  def test_get_updated_entries_and_save_user_readings
    # 登録済みの記事を一旦クリア
    BoardEntry.delete_all
    BoardEntryComment.delete_all
    entries = []

    # 30分以内に更新されたentry
    entries << BoardEntry.create(store_entry_params({ :user_id => @a_user.id,
                                                      :last_updated => Time.now.ago(60*10),
                                                      :symbol => "gid:#{@a_protected_group1}"}))

    # 30分以上前に更新されたentry
    entries << BoardEntry.create(store_entry_params({ :user_id => @a_user.id,
                                                      :last_updated => Time.now.ago(60*31),
                                                      :symbol => "gid:#{@a_protected_group1}"}))

    # 30分以内に更新された他のentry
    entries << BoardEntry.create(store_entry_params({ :user_id => @a_user.id,
                                                      :last_updated => Time.now.ago(60*10),
                                                      :symbol => "gid:#{@a_protected_group1}"}))

    updated_entries = BatchMakeUserReadings.get_updated_entries
    assert_equal 2, updated_entries.size
    assert_equal entries[0].id, updated_entries[0].id
    assert_equal entries[2].id, updated_entries[1].id

    # 30分以内に更新されたentryにコメント追加 => 更新されたと判断する
    entries[0].board_entry_comments.create({ :contents => "comment",
                                            :user_id => @a_user.id})
    updated_entries = BatchMakeUserReadings.get_updated_entries
    assert_equal 2, updated_entries.size
    assert_equal entries[0].id, updated_entries[0].id
    assert_equal entries[2].id, updated_entries[1].id

    # 30分以上前に更新されたentryに、30分以上前にコメント追加 => 更新されたと判断しない
#    ActiveRecord::Base.record_timestamps = false
#    entries[1].board_entry_comments.create({ :contents => "comment",
#                                            :user_id => @a_user.id,
#                                            :created_on => Time.now.ago(60*32),
#                                            :updated_on => Time.now.ago(60*32)})
#    updated_entries = BatchMakeUserReadings.get_updated_entries
# FIXME なぜか件数が3になってしまう。更新されたと判断されている？
#    assert_equal 2, updated_entries.size
#    assert_equal entries[0].id, updated_entries[0].id
#    assert_equal entries[2].id, updated_entries[1].id

    ActiveRecord::Base.record_timestamps = true
    # 30分以上前に更新されたentryにコメント追加 => 更新されたと判断する
    entries[1].board_entry_comments.create({ :contents => "comment",
                                            :user_id => @a_user.id})


    updated_entries = BatchMakeUserReadings.get_updated_entries
    assert_equal 3, updated_entries.size
    assert_equal entries[0].id, updated_entries[0].id
    assert_equal entries[1].id, updated_entries[1].id
    assert_equal entries[2].id, updated_entries[2].id


    # 自分が書いたコメント => アンテナに反映しない
    BatchMakeUserReadings.save_user_reading updated_entries[0].user_id, updated_entries[0]
    assert_equal 0, UserReading.find(:all).size
    # 自分が書いたコメント => アンテナに反映しない
    BatchMakeUserReadings.save_user_reading updated_entries[1].user_id, updated_entries[1]
    assert_equal 0, UserReading.find(:all).size

    # 他人が書いたコメント => アンテナに反映する
    BatchMakeUserReadings.save_user_reading @a_group_owned_user.id, updated_entries[0]
    assert_equal 1, UserReading.find(:all).size
    # 他人が書いたコメント => アンテナに反映する
    BatchMakeUserReadings.save_user_reading @a_group_owned_user.id, updated_entries[1]
    assert_equal 2, UserReading.find(:all).size

  end

private
  def store_entry_params params={}
    entry_template = {
      :title => "test",
      :contents => "test",
      :date => Date.today,
      :category => "",
      :entry_type => "BBS",
      :ignore_times => false,
      :user_entry_no => 1,
      :editor_mode => "hiki",
      :lock_version => 0,
      :publication_type => "public",
      :entry_trackbacks_count => 0,
      :board_entry_comments_count => 0
    } # user_id, last_updated, symbolが未設定

    params.each do |key, value|
      entry_template.store(key, value)
    end
    return entry_template
  end
end

describe BatchMakeUserReadings do
  describe "お知らせの新着通知" do
    before do
      @create_user = create_user(:user_uid_options => {})
      @notice_user = create_user(:user_uid_options => { :uid => "54321" })
    end

    subject { UserReading.find_by_user_id_and_board_entry_id(@notice_user.id, @entry.id) }

    it "閲覧可能な記事を作成したとき、未読に登録されること" do
      @entry = create_board_entry(:user => @create_user, :aim_type => BoardEntry::ANTENNA_AIM_TYPES.rand, :last_updated => Time.now)
      BatchMakeUserReadings.execution
      should_not be_nil
    end
    it "閲覧できない記事を作成したとき、未読に登録されないこと" do
      @entry = create_board_entry(:user => @create_user, :aim_type => BoardEntry::ANTENNA_AIM_TYPES.rand, :publication_type => "private", :last_updated => Time.now)
      BatchMakeUserReadings.execution
      should be_nil
    end
    it "コメントを追加したとき、未読に登録されないこと" do
      @entry = create_board_entry(:user => @create_user, :aim_type => BoardEntry::ANTENNA_AIM_TYPES.rand, :last_updated => 2.hour.ago)
      create_board_entry_comment(:board_entry_id => @entry.id, :user_id => @create_user.id)
      BatchMakeUserReadings.execution
      should be_nil
    end
  end
end
