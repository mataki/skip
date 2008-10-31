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

require File.dirname(__FILE__) + '/../spec_helper'

describe BatchMakeRanking do
  before do
    @exec_date = Date.today
    @maker = BatchMakeRanking.new
  end
  # アクセス数
  describe BatchMakeRanking, '#create_access_ranking' do
    describe '更新日付が実行日のBoardEntryPointが存在する場合' do
      before do
        setup_test_data
      end
      describe 'BoardEntryPointのアクセス数(access_count)が1以上のレコードが存在する場合' do
        before do
          @board_entry_point.update_attributes!(:access_count => 1)
        end
        describe '記事が全公開の場合' do
          before do
            @maker.stub!(:published?).and_return(true)
          end
          it 'ランキングが生成されること' do
            lambda do
              @maker.send(:create_access_ranking, @exec_date)
            end.should change(Ranking, :count)
          end
        end
        describe '記事が全公開ではない場合' do
          before do
            @maker.stub!(:published?).and_return(false)
          end
          it 'ランキングが生成されないこと' do
            @maker.should_not_receive(:create_ranking_by_entry)
            @maker.send(:create_access_ranking, @exec_date)
          end
        end
      end
      describe 'BoardEntryPointのアクセス数(access_count)が1以上のレコードが存在しない場合' do
        before do
          @board_entry_point.update_attributes!(:access_count => 0)
        end
        it 'ランキングが生成されないこと' do
          @maker.should_not_receive(:create_ranking_by_entry)
          @maker.send(:create_access_ranking, @exec_date)
        end
      end
    end
  end

  # goodjob数
  describe BatchMakeRanking, '#create_point_ranking' do
    describe '更新日付が実行日のBoardEntryPointが存在する場合' do
      before do
        setup_test_data
      end
      describe 'BoardEntryPointのpointが1以上のレコードが存在する場合' do
        before do
          @board_entry_point.update_attributes!(:point => 1)
        end
        describe '記事が全公開の場合' do
          before do
            @maker.stub!(:published?).and_return(true)
          end
          it 'ランキングが生成されること' do
            lambda do
              @maker.send(:create_point_ranking, @exec_date)
            end.should change(Ranking, :count)
          end
        end
        describe '記事が全公開ではない場合' do
          before do
            @maker.stub!(:published?).and_return(false)
          end
          it 'ランキングが生成されないこと' do
            @maker.should_not_receive(:create_ranking_by_entry)
            @maker.send(:create_point_ranking, @exec_date)
          end
        end
      end
      describe 'BoardEntryPointのpointが1以上のレコードが存在しない場合' do
        before do
          @board_entry_point.update_attributes!(:point => 0)
        end
        it 'ランキングが生成されないこと' do
          @maker.should_not_receive(:create_ranking_by_entry)
          @maker.send(:create_point_ranking, @exec_date)
        end
      end
    end
  end

  # コメント数
  describe BatchMakeRanking, '#create_comment_ranking' do
    describe '更新日付が実行日のBoardEntryが存在する場合' do
      before do
        setup_test_data
      end
      describe 'BoardEntryのコメント数(board_entry_comments_count)が1以上のレコードが存在する場合' do
        before do
          # board_entry_comments_countはカウンタキャッシュなので実際に関連レコードを作成しないと更新されない
          # @board_entry.update_attributes!(:board_entry_comments_count => 1)
          @board_entry_comment = create_board_entry_comment(:user_id => @user.id, :board_entry_id => @board_entry.id)
        end
        describe '記事が全公開の場合' do
          before do
            @maker.should_receive(:published?).and_return(true)
          end
          it 'ランキングが生成されること' do
            lambda do
              @maker.send(:create_comment_ranking, @exec_date)
            end.should change(Ranking, :count)
          end
        end
        describe '記事が全公開ではない場合' do
          before do
            @maker.stub!(:published?).and_return(false)
          end
          it 'ランキングが生成されないこと' do
            @maker.should_not_receive(:create_ranking_by_entry)
            @maker.send(:create_comment_ranking, @exec_date)
          end
        end
      end
      describe 'BoardEntryのコメント数(board_entry_comments_count)が1以上のレコードが存在しない場合' do
        it 'ランキングが生成されないこと' do
          @maker.should_not_receive(:create_ranking_by_entry)
          @maker.send(:create_comment_ranking, @exec_date)
        end
      end
    end
  end

  # 投稿数
  describe BatchMakeRanking, '#create_post_ranking' do
    describe '更新日付が実行日のBoardEntryが存在する場合' do
      before do
        setup_test_data
      end
      describe 'BoardEntryの記事種別(entry_type)が日記(DIARY)なレコードが存在する場合' do
        before do
          @board_entry.symbol = "uid:#{@user.uid}"
          @board_entry.update_attributes!(:entry_type => BoardEntry::DIARY)
        end
        it 'ランキングが生成されること' do
          lambda do
            @maker.send(:create_post_ranking, @exec_date)
          end.should change(Ranking, :count)
        end
      end
      describe 'BoardEntryの記事種別(entry_type)が日記(DIARY)なレコードが存在しない場合' do
        before do
          @board_entry.update_attributes!(:entry_type => 'BBS')
        end
        it 'ランキングが生成されないこと' do
          @maker.should_not_receive(:create_ranking_by_entry)
          @maker.send(:create_post_ranking, @exec_date)
        end
      end
    end
  end

  # 訪問者数
  describe BatchMakeRanking, '#create_visited_ranking' do
    describe '更新日付が実行日のUserAccessが存在する場合' do
      before do
        setup_test_data
        @user_access = create_user_access(:user_id => @user.id)
      end
      describe 'UserAccessのアクセス数(access_count)が1以上のレコードが存在する場合' do
        before do
          @user_access.update_attributes(:access_count => 1)
        end
        it 'ランキングが生成されること' do
          lambda do
            @maker.send(:create_visited_ranking, @exec_date)
          end.should change(Ranking, :count)
        end
      end
      describe 'UserAccessのアクセス数(access_count)が1以上のレコードが存在しない場合' do
        before do
          @user_access.update_attributes(:access_count => 0)
        end
        it 'ランキングが生成されないこと' do
          @maker.should_not_receive(:create_ranking_by_entry)
          @maker.send(:create_visited_ranking, @exec_date)
        end
      end
    end
  end

  # コメンテータ
  describe BatchMakeRanking, '#create_commentator_ranking' do
    describe '更新日付が実行日以前のBoardEntryCommentが存在する場合' do
      before do
        setup_test_data
        @board_entry_comment = create_board_entry_comment(:user_id => @user.id, :board_entry_id => @board_entry.id)
      end
      describe '実行日のコメントが存在する場合' do
        before do
          @board_entry_comment.update_attributes!(:updated_on => @exec_date)
        end
        it 'ランキングが生成されること' do
          lambda do
            @maker.send(:create_commentator_ranking, @exec_date)
          end.should change(Ranking, :count)
        end
      end
      describe '実行日のコメントが存在しない場合' do
        before do
          @board_entry_comment.update_attributes!(:updated_on => @exec_date.tomorrow)
        end
        it 'ランキングが生成されないこと' do
          @maker.should_not_receive(:create_ranking_by_entry)
          @maker.send(:create_commentator_ranking, @exec_date)
        end
      end
    end
  end

  describe BatchMakeRanking, "#user_url" do
    it "URLが正しく返されること" do
      @maker.send(:user_url, "hoge").should == "#{Admin::Setting.protocol_by_initial_settings_default}#{Admin::Setting.host_and_port_by_initial_settings_default}/user/hoge"
    end
  end

  describe BatchMakeRanking, "#page_url" do
    it "URLが正しく返されること" do
      @maker.send(:page_url, 1).should == "#{Admin::Setting.protocol_by_initial_settings_default}#{Admin::Setting.host_and_port_by_initial_settings_default}/page/1"
    end
  end

  def setup_test_data
    @user = create_user(:user_options => {:name => 'とあるゆーざ', :status => 'ACTIVE'},
                        :user_profile_options => {},
                        :user_uid_options => {:uid => SkipFaker.rand_char})
    @board_entry = create_board_entry(:user_id => @user.id)
    @board_entry_point = create_board_entry_point(:board_entry_id => @board_entry.id, :updated_on => Time.now)
  end

  def create_board_entry options = {}
    board_entry = BoardEntry.new({:title => 'とある記事',
                                 :contents => 'とある記事の内容',
                                 :date => Date.today,
                                 :user_id => 1,
                                 :last_updated => Date.today}.merge(options))
    board_entry.save!
    board_entry
  end

  def create_board_entry_point options = {}
    board_entry_point = BoardEntryPoint.new({:board_entry_id => 1}.merge(options))
    board_entry_point.save!
    board_entry_point
  end

  def create_user_access options = {}
    user_access = UserAccess.new({:user_id => 1,
                                  :last_access => Time.now,
                                  :access_count => 0}.merge(options))
    user_access.save!
    user_access
  end

end
