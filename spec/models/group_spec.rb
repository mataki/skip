# SKIP(Social Knowledge & Innovation Platform)
# Copyright (C) 2008-2009 TIS Inc.
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
    it 'gidがユニークであること' do
      create_group(:gid => 'SKIP_GID')
      @group.gid = 'SKIP_GID'
      @group.valid?.should be_false
      # 大文字小文字が異なる場合もNG
      @group.gid = 'Skip_gid'
      @group.valid?.should be_false
    end
    it 'default_publication_typeに、publicを指定できること' do
      @group.default_publication_type = 'public'
      @group.valid?.should be_true
    end
    it 'default_publication_typeに、privateを指定できること' do
      @group.default_publication_type = 'private'
      @group.valid?.should be_true
    end
    it 'default_publication_typeに、publicとprivate以外を指定するとエラーになること' do
      @group.default_publication_type = 'foo'
      @group.valid?.should be_false
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
    describe "あるユーザの管理しているグループに承認待ちのユーザがいる場合" do
      before do
        @alice = create_user :user_options => {:name => 'アリス', :admin => true}, :user_uid_options => {:uid => 'alice'}
        @group = create_group(:gid => 'skip_group', :name => 'SKIPグループ') do |g|
          g.group_participations.build(:user_id => @alice.id, :owned => true, :waiting => true)
        end
      end
      it '指定したユーザに対する承認待ちのグループが取得できること' do
        Group.find_waitings(@alice.id).first.should == @group
      end
      describe '承認待ちになっているグループが論理削除された場合' do
        before do
          @group.logical_destroy
        end
        it '対象のグループが取得できないこと' do
          Group.find_waitings(@alice.id).should be_empty
        end
      end
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

  describe Group, '.gid_by_category' do
    before do
      Group.delete_all
      @group_category = create_group_category
      @vim_group = create_group :gid => 'vim_group', :group_category_id => @group_category.id
      @emacs_group = create_group :gid => 'emacs_group', :group_category_id => @group_category.id
    end
    it '対象のカテゴリに対するgidのハッシュが返ること' do
      Group.gid_by_category.should == {@group_category.id => ['gid:vim_group', 'gid:emacs_group']}
    end
    it '論理削除されたグループのgidは含まれないこと' do
      @vim_group.logical_destroy
      Group.gid_by_category.should == {@group_category.id => ['gid:emacs_group']}
    end
  end

  describe Group, "#logical_after_destroy グループに掲示板と共有ファイルがある場合" do
    fixtures :groups, :board_entries, :share_files, :users, :user_uids
    before(:each) do
      @group = groups(:a_protected_group1)
      @board_entry = board_entries(:a_entry)
      @share_file = share_files(:a_share_file)
      @board_entry.symbol = @group.symbol
      @board_entry.entry_type = BoardEntry::GROUP_BBS
      @board_entry.category = @board_entry.comma_category
      @board_entry.save!

      @share_file.owner_symbol = @group.symbol
      @share_file.stub!(:updatable?).and_return(true)
      @share_file.save!
      File.stub!(:delete)
    end

    it { lambda { @group.logical_destroy }.should change(BoardEntry, :count).by(-1) }
    it { lambda { @group.logical_destroy }.should change(ShareFile, :count).by(-1) }
  end

  describe Group, "count_by_category" do
    before do
      @alice = create_user :user_options => {:name => 'アリス', :admin => true}, :user_uid_options => {:uid => 'alice'}
      @dev_category = create_group_category :code => 'dev'
      @vim_group = create_group :gid => 'vim_group', :group_category_id => @dev_category.id do |g|
        g.group_participations.build(:user_id => @alice.id, :owned => true)
      end
      @tom = create_user :user_options => {:name => 'トム', :admin => true}, :user_uid_options => {:uid => 'toom'}
      @emacs_group = create_group :gid => 'emacs_group', :group_category_id => @dev_category.id do |g|
        g.group_participations.build(:user_id => @tom.id, :owned => true)
      end
      @life_category = create_group_category :code => 'life'
      @move_group = create_group :gid => 'move_group', :group_category_id => @life_category.id do |g|
        g.group_participations.build(:user_id => @tom.id, :owned => true)
      end
    end

    describe 'ユーザを指定しない場合' do
      it "グループのカテゴリとそのカテゴリのグループ数および全グループ数を返す" do
        group_counts, total_count = Group.count_by_category
        group_counts[@dev_category.id].should == 2
        group_counts[@life_category.id].should == 1
        total_count.should == 3
      end
    end

    describe 'ユーザを指定する場合' do
      it 'ユーザの所属するグループのカテゴリとそのカテゴリのグループ数及び全グループ数を返す' do
        group_counts, total_count = Group.count_by_category(@alice.id)
        group_counts[@dev_category.id].should == 1
        group_counts[@life_category.id].should == 0
        total_count.should == 1
      end
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

  describe Group, '#synchronize_groups' do
    describe '2つの同期対象グループが存在する場合' do
      before do
        Group.delete_all
        Admin::Setting.stub!(:protocol_by_initial_settings_default).and_return('http://')
        Admin::Setting.stub!(:host_and_port_by_initial_settings_default).and_return('localhost:3000')
        bob = create_user :user_options => {:name => 'ボブ', :admin => false}, :user_uid_options => {:uid => 'boob'}
        alice = create_user :user_options => {:name => 'アリス', :admin => true}, :user_uid_options => {:uid => 'alice'}
        tom = create_user :user_options => {:name => 'トム', :admin => true}, :user_uid_options => {:uid => 'toom'}
        group_category_id = create_group_category(:code => 'study').id
        # Vim勉強会には@bob, @aliceが参加していて、@tomは参加待ち
        @vim_group = create_group :name => 'Vim勉強会', :gid => 'vim_study', :group_category_id => group_category_id do |g|
          g.group_participations.build(:user_id => bob.id, :owned => true)
          g.group_participations.build(:user_id => alice.id, :owned => false)
          g.group_participations.build(:user_id => tom.id, :waiting => true)
        end
        # Emacs勉強会には@bobのみ参加している
        @emacs_group = create_group :name => 'Emacs勉強会', :gid => 'emacs_study', :group_category_id => group_category_id, :deleted_at => Time.now do |g|
          g.group_participations.build(:user_id => bob.id, :owned => true)
        end

        @groups = Group.synchronize_groups
        @vim_group_attr, @emacs_group_attr = @groups
      end
      it '二件のグループ同期情報を取得できること' do
        @groups.size.should == 2
      end
      it 'Vim勉強会の情報が正しく設定されていること' do
        @vim_group_attr.should == ['vim_study', 'vim_study', 'Vim勉強会', %w[boob alice].map{|u| "http://localhost:3000/id/#{u}" }, false]
      end
      it 'Emacs勉強会の情報が正しく設定されていること' do
        @emacs_group_attr.should == ['emacs_study', 'emacs_study', 'Emacs勉強会', ["http://localhost:3000/id/boob"], true]
      end

      describe 'Vim勉強会のグループが4分59秒前に更新、Emacs勉強会のグループが5分前に更新されており、5分以内に更新があったグループのみ取得する場合' do
        before do
          Time.stub!(:now).and_return(Time.local(2009, 6, 2, 0, 0, 0))
          Group.record_timestamps = false
          @vim_group.update_attribute(:updated_on, Time.local(2009, 6, 1, 23, 54, 59))
          @emacs_group.update_attribute(:updated_on, Time.local(2009, 6, 1, 23, 55, 0))
          @groups = Group.synchronize_groups 5
          @emacs_group_attr = @groups.first
        end
        it '1件のグループ同期情報を取得できること' do
          @groups.size.should == 1
        end
        it 'Emacs勉強会の情報が正しく設定されていること' do
          @emacs_group_attr.should == ['emacs_study', 'emacs_study', 'Emacs勉強会', ["http://localhost:3000/id/boob"], true]
        end
        after do
          Group.record_timestamps = true
        end
      end
    end
  end

  def valid_group
    group = Group.new({
      :name => 'name',
      :description =>  'description',
      :protected => true,
      :gid => 'valid_gid',
      :group_category_id => create_group_category(:initial_selected => true, :code => 'VALID').id
    })
    group
  end

  def create_group_participation(options = {})
    group_participation = GroupParticipation.new({:user_id => 1, :group_id => 1, :waiting => 0, :owned => 0, :favorite => 0}.merge(options))
    group_participation.save!
    group_participation
  end
end
