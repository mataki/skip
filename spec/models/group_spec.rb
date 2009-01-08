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

describe Group do
  describe Group, '.initialize' do
    before do
      @group_category = create_group_category(:initial_selected => true)
    end
    describe 'group_category_idの指定がない場合' do
      it { Group.new.group_category_id.should == @group_category.id }
    end
    describe 'group_category_idの指定がある場合' do
      it { Group.new(:group_category_id => 1).group_category_id.should == 1 }
    end
  end

  describe Group, 'validation' do
    before do
      @group = valid_group
    end
    describe '.validate' do
      describe 'group_category_idに対するGroupCategoryが存在する場合' do
        before do
          GroupCategory.should_receive(:find_by_id).and_return(mock(GroupCategory))
        end
        it 'エラーにならないこと' do
          lambda do
            @group.validate
          end.should_not change(@group.errors, :size)
        end
      end
      describe 'group_category_idに対するGroupCategoryが存在しない場合' do
        before do
          GroupCategory.should_receive(:find_by_id).and_return(nil)
        end
        it 'エラーになること' do
          lambda do
            @group.validate
          end.should change(@group.errors, :size)
        end
      end
    end
  end

  describe Group, "承認待ちのユーザがいるとき" do
    before(:each) do
      @group = Group.new
      @group_participations = [GroupParticipation.new({ :waiting => true })]
      @group.should_receive(:group_participations).and_return(stub('group_participations', :find => @group_participations))
    end

    it "has_waitingはtrueを返す" do
      @group.has_waiting.should be_true
    end
  end

  describe Group, "承認待ちのユーザがいないとき" do
    before(:each) do
      @group = Group.new
      @group_participations = []
      @group.should_receive(:group_participations).and_return(stub('group_participations', :find => @group_participations))
    end

    it "has_waiting false " do
      @group.has_waiting.should be_false
    end
  end

  describe Group, "あるグループがあるとき" do
    fixtures :users
    before(:each) do
      @group = Group.new({ :name => 'hoge', :gid => 'hoge', :description => 'hoge', :protected => '1',
                         :created_on => Time.now, :updated_on => Time.now })
      @link_group = mock_model(Group)
      @link_group.stub!(:name).and_return('foo')
      @link_group.stub!(:symbol).and_return('foo')
      Group.should_receive(:find_by_gid).twice.and_return(@link_group)
    end

    it "イベント招待メールが投稿できる" do
      lambda {
        @group.create_entry_invite_group(users(:a_user).id, 'hoge', ['uid:hoge'])
      }.should change(BoardEntry, :count).by(1)
    end
  end

  describe Group, "Group.find_waitings" do
    fixtures :groups
    describe "あるユーザの管理しているグループに承認待ちのユーザがいる場合" do

      before(:each) do
        @participation = mock_model(GroupParticipation)
        @group_id = groups(:a_protected_group1).id
        @participation.stub!(:group_id).and_return(@group_id)
        GroupParticipation.stub!(:find).and_return([@participation])
      end

      it { Group.find_waitings(1).first.id.should == @group_id }
    end

    describe "あるユーザの管理しているグループに承認待ちのユーザがいない場合" do
      before(:each) do
        GroupParticipation.stub!(:find).and_return([])
      end

      it { Group.find_waitings(1).should be_empty }
    end
  end

  describe Group, "#get_owners あるグループに管理者がいる場合" do
    before(:each) do
      @group = Group.new
      @user = mock_model(User)
      @group_participation = mock_model(GroupParticipation)
      @group_participation.stub!(:user).and_return(@user)
      @group_participation.stub!(:owned).and_return(true)
    @group.should_receive(:group_participations).and_return([@group_participation])
      end

    it "管理者ユーザが返る" do
      @group.get_owners.should == [@user]
    end
  end

  describe Group, "#after_destroy グループに掲示板と共有ファイルがある場合" do
    fixtures :groups, :board_entries, :share_files, :users, :user_uids
    before(:each) do
      @group = groups(:a_protected_group1)
      @board_entry = board_entries(:a_entry)
      @share_file = share_files(:a_share_file)
      @board_entry.symbol = @group.symbol
      @board_entry.entry_type = BoardEntry::GROUP_BBS
      @board_entry.save!

      @share_file.owner_symbol = @group.symbol
      @share_file.stub!(:updatable?).and_return(true)
      @share_file.save!
      File.stub!(:delete)
    end

    it { lambda { @group.destroy }.should change(BoardEntry, :count).by(-1) }
    it { lambda { @group.destroy }.should change(ShareFile, :count).by(-1) }
  end

  describe Group, "count_by_category" do
    before(:each) do
      @group1 = mock_model(Group)
      @group1.stub!(:group_category_id).and_return('1')
      @group1.stub!(:count).and_return('2')
      @group2 = mock_model(Group)
      @group2.stub!(:group_category_id).and_return('2')
      @group2.stub!(:count).and_return('1')
      Group.should_receive(:find).and_return([@group1,@group2])
    end

    it "グループのカテゴリとそのカテゴリのグループ数および全グループ数を返す" do
      group_counts, total_count = Group.count_by_category
      group_counts['1'].should == 2
      group_counts['2'].should == 1
      total_count.should == 3
    end
  end

  describe Group, "#participation_users" do
    before(:each) do
      @group = Group.new
      @group.stub!(:id).and_return(1)
      @user = mock_model(User)
    end

    describe "引数が何も与えられていない場合" do
      before(:each) do
        options = { :conditions => ['group_participations.group_id = ? ',1], :include => 'group_participations' }
        User.should_receive(:find).with(:all, options).and_return([@user])
      end
      it "conditionsとincludeが設定されていること" do
        @group.participation_users.should == [@user]
      end
    end

    describe "waitingオプションがあった場合　conditionsに承認待ちを限定する条件があること" do
      before(:each) do
        options = { :conditions => ['group_participations.group_id = ? and group_participations.waiting = ? ',1,true],
          :include => 'group_participations' }
        User.should_receive(:find).with(:all, options).and_return([@user])
      end
      it { @group.participation_users({ :waiting => true }).should == [@user] }
    end

    describe "ownedオプションがあった場合" do
      before(:each) do
        options = { :conditions => ['group_participations.group_id = ? and group_participations.owned = ? ',1,true],
          :include => 'group_participations' }
        User.should_receive(:find).with(:all, options).and_return([@user])
      end
      it { @group.participation_users({ :owned => true }).should == [@user] }
    end
  end

  describe Group, '#participating?' do
    before do
      @user = stub_model(User, :id => 99)
      @group = create_group
    end
    describe '指定したユーザがグループ参加者(参加済み)の場合' do
      before do
        group_participation = create_group_participation(:user_id => @user.id, :group_id => @group.id)
      end
      it 'trueが返ること' do
        @group.participating?(@user).should be_true
      end
    end
    describe '指定したユーザがグループ参加者(参加待ち)の場合' do
      before do
        group_participation = create_group_participation(:user_id => @user.id, :group_id => @group.id, :waiting => true)
      end
      it 'falseが返ること' do
        @group.participating?(@user).should be_false
      end
    end
    describe '指定したユーザがグループ管理者(参加済み)の場合' do
      before do
        group_participation = create_group_participation(:user_id => @user.id, :group_id => @group.id, :waiting => false, :owned => true)
      end
      it 'trueが返ること' do
        @group.participating?(@user).should be_true
      end
    end
    describe '指定したユーザがグループ管理者(参加待ち)の場合' do
      before do
        group_participation = create_group_participation(:user_id => @user.id, :group_id => @group.id, :waiting => true, :owned => true)
      end
      it 'falseが返ること' do
        @group.participating?(@user).should be_false
      end
    end
    describe '指定したユーザがグループ未参加者の場合' do
      before do
        group_participation = create_group_participation(:user_id => @user.id + 1, :group_id => @group.id)
      end
      it 'falseが返ること' do
        @group.participating?(@user).should be_false
      end
    end
  end

  describe Group, '#administrator? ' do
    before do
      @user = stub_model(User, :id => 99)
      @group = create_group
    end
    describe '指定したユーザがグループ参加者(参加済み)の場合' do
      before do
        group_participation = create_group_participation(:user_id => @user.id, :group_id => @group.id)
      end
      it 'falseが返ること' do
        @group.administrator?(@user).should be_false
      end
    end
    describe '指定したユーザがグループ参加者(参加待ち)の場合' do
      before do
        group_participation = create_group_participation(:user_id => @user.id, :group_id => @group.id, :waiting => true)
      end
      it 'falseが返ること' do
        @group.participating?(@user).should be_false
      end
    end
    describe '指定したユーザがグループ管理者(参加済み)の場合' do
      before do
        group_participation = create_group_participation(:user_id => @user.id, :group_id => @group.id, :waiting => false, :owned => true)
      end
      it 'trueが返ること' do
        @group.participating?(@user).should be_true
      end
    end
    describe '指定したユーザがグループ管理者(参加待ち)の場合' do
      before do
        group_participation = create_group_participation(:user_id => @user.id, :group_id => @group.id, :waiting => true, :owned => true)
      end
      it 'falseが返ること' do
        @group.participating?(@user).should be_false
      end
    end
    describe '指定したユーザがグループ未参加者の場合' do
      before do
        group_participation = create_group_participation(:user_id => @user.id + 1, :group_id => @group.id)
      end
      it 'falseが返ること' do
        @group.participating?(@user).should be_false
      end
    end
  end

  def valid_group
    group = Group.new({
      :name => '',
      :description =>  '',
      :protected => true,
      :gid => '',
      :group_category_id => create_group_category(:initial_selected => true).id
    })
    group
  end

  def create_group(options = {})
    group = Group.new({:name => 'SKIP開発', :description => 'SKIP開発中', :protected => false, :gid => 'skip_dev', :group_category_id => create_group_category(:initial_selected => true).id}.merge(options))
    group.save!
    group
  end

  def create_group_participation(options = {})
    group_participation = GroupParticipation.new({:user_id => 1, :group_id => 1, :waiting => 0, :owned => 0, :favorite => 0}.merge(options))
    group_participation.save!
    group_participation
  end
end
