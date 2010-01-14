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

describe SiteCount do
  fixtures :users, :board_entries, :board_entry_comments, :site_counts, :user_uids

  # TODO RSpec化してSiteCountのテストクラスへ移動したら削除する
  # 一ヶ月以内に記事を書いたユーザ
  def test_calc_write_at_month
    count = SiteCount.calc_writer_at_month Time.now
    assert_equal 1, count

    # 1ヶ月以内に作成されたブログ（user:1）
    user = @a_user
    entry = BoardEntry.create(store_entry_params({ :user_id => user.id,
                                                   :last_updated => Time.now.last_month.tomorrow,
                                                   :symbol => user.symbol,
                                                   :entry_type => "DIARY"}))
    entry.update_attributes(:created_on => Time.now.last_month.tomorrow)

    count = SiteCount.calc_writer_at_month Time.now
    assert_equal 1, count


    # 1ヶ月以内に作成されたブログ（user:1）2つ目
    user = @a_user
    entry = BoardEntry.create(store_entry_params({ :user_id => user.id,
                                                   :last_updated => Time.now.last_month.tomorrow,
                                                   :symbol => user.symbol,
                                                   :entry_type => "DIARY"}))
    entry.update_attributes(:created_on => Time.now.last_month.tomorrow)

    count = SiteCount.calc_writer_at_month Time.now
    assert_equal 1, count


    # 1ヶ月以上前にに作成されたブログ（user:2）
    user = @a_user
    entry = BoardEntry.create(store_entry_params({ :user_id => user.id,
                                                   :last_updated => Time.now.last_month.yesterday,
                                                   :symbol => user.symbol,
                                                   :entry_type => "DIARY"}))
    entry.update_attributes(:created_on => Time.now.last_month.yesterday)

    count = SiteCount.calc_writer_at_month Time.now
    assert_equal 1, count

    # 1ヶ月以内にに作成されたBBS（user:2）
    user = @a_user
    bbs = BoardEntry.create(store_entry_params({ :user_id => user.id,
                                                 :last_updated => Time.now.last_month.tomorrow,
                                                 :symbol => "gid:skipteam",
                                                 :entry_type => "BBS"}))
    bbs.update_attributes(:created_on => Time.now.last_month.tomorrow)

    count = SiteCount.calc_writer_at_month Time.now
    assert_equal 1, count

    # 1ヶ月以内に作成されたコメント(user:3)
    user = @a_user
    comment = BoardEntryComment.create(:board_entry_id => bbs.id, :contents => "test", :user_id => user.id)

    count = SiteCount.calc_writer_at_month Time.now
    assert_equal 1, count
  end

  def test_calc_user_access_at_month
    site_counts = []
    # 2006/11月において、土日祝日以外のアクセス数を100としたデータ
    #                       mon,tue,wed,thu,fri,sat,sun
    november_user_counts = [        100,100,  0,  0,  0,
                            100,100,100,100,100,  0,  0,
                            100,100,100,100,100,  0,  0,
                            100,100,100,  0,100,  0,  0,
                            100,100,100,100
                           ]

    current_time = Time.local(2006, 11, 1)
    november_user_counts.size.times { |i|
      site_counts << SiteCount.new(:today_user_count => november_user_counts[i], :created_on => current_time)
      current_time = current_time.tomorrow
    }

    res = SiteCount.calc_user_access_at_month_only_weekday site_counts
    assert_equal 100, res
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
