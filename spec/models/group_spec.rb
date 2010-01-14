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

  describe Group, "承認が必要なグループが不要にが変更されたとき" do
    before do
      @group = create_group(:protected => true)
      @user = create_user
      @participation = @group.group_participations.create!(:user=>@user, :waiting => true)
      @group.reload; @user.reload
    end
    it "正しい状態であること" do
      @group.users.should == []
      @group.group_participations.waiting.should be_include(@participation)
      @user.group_participations.waiting.should be_include(@participation)
      @group.users.should_not be_include(@user)
    end
    it "承認待ちのユーザは全て参加済みになっていること" do
      @group.update_attributes!(:protected => false)
      @group.users.should be_include(@user)
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

  describe Group, ".has_waiting_for_approval" do
    describe "あるユーザの管理しているグループに承認待ちのユーザがいる場合" do
      before do
        @alice = create_user :user_options => {:name => 'アリス', :admin => true}, :user_uid_options => {:uid => 'alice'}
        @group = create_group(:gid => 'skip_group', :name => 'SKIPグループ') do |g|
          g.group_participations.build(:user_id => @alice.id, :owned => true, :waiting => true)
        end
      end
      it '指定したユーザに対する承認待ちのグループが取得できること' do
        Group.has_waiting_for_approval(@alice).first.should == @group
      end
      describe '承認待ちになっているグループが論理削除された場合' do
        before do
          @group.logical_destroy
        end
        it '対象のグループが取得できないこと' do
          Group.has_waiting_for_approval(@alice).should be_empty
        end
      end
    end
  end

  describe Group, "#owners あるグループに管理者がいる場合" do
    before do
      @alice = create_user :user_options => {:name => 'アリス', :admin => true}, :user_uid_options => {:uid => 'alice'}
      @jack = create_user :user_options => {:name => 'ジャック', :admin => true}, :user_uid_options => {:uid => 'jack'}
      @group = create_group(:gid => 'skip_group', :name => 'SKIPグループ') do |g|
        g.group_participations.build(:user_id => @alice.id, :owned => true)
        g.group_participations.build(:user_id => @jack.id)
      end
    end

    it "管理者ユーザが返る" do
      @group.owners.should == [@alice]
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

  describe Group, "#logical_after_destroy グループに掲示板、掲示板コメント、共有ファイルがある場合" do
    fixtures :groups, :board_entries, :share_files, :users, :user_uids
    before(:each) do
      @group = groups(:a_protected_group1)
      @board_entry = board_entries(:a_entry)
      @share_file = share_files(:a_share_file)
      @board_entry.symbol = @group.symbol
      @board_entry.entry_type = BoardEntry::GROUP_BBS
      @board_entry.category = ''
      @board_entry.save!
      @board_entry.board_entry_comments.create! :contents => 'contents', :user => create_user

      @share_file.owner_symbol = @group.symbol
      @share_file.stub!(:updatable?).and_return(true)
      @share_file.save!
      File.stub!(:delete)
    end

    it { lambda { @group.logical_destroy }.should change(BoardEntry, :count).by(-1) }
    it { lambda { @group.logical_destroy }.should change(ShareFile, :count).by(-1) }
    it { lambda { @group.logical_destroy }.should change(BoardEntryComment, :count).by(-1) }
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
        @group.administrator?(@user).should be_false
      end
    end
    describe '指定したユーザがグループ管理者(参加済み)の場合' do
      before do
        group_participation = create_group_participation(:user_id => @user.id, :group_id => @group.id, :waiting => false, :owned => true)
      end
      it 'trueが返ること' do
        @group.administrator?(@user).should be_true
      end
    end
    describe '指定したユーザがグループ管理者(参加待ち)の場合' do
      before do
        group_participation = create_group_participation(:user_id => @user.id, :group_id => @group.id, :waiting => true, :owned => true)
      end
      it 'falseが返ること' do
        @group.administrator?(@user).should be_false
      end
    end
    describe '指定したユーザがグループ未参加者の場合' do
      before do
        group_participation = create_group_participation(:user_id => @user.id + 1, :group_id => @group.id)
      end
      it 'falseが返ること' do
        @group.administrator?(@user).should be_false
      end
    end
  end

  describe Group, '#synchronize_groups' do
    describe '2つの同期対象グループが存在する場合' do
      before do
        Group.delete_all
        SkipEmbedded::InitialSettings['host_and_port'] = 'localhost:3000'
        SkipEmbedded::InitialSettings['protocol'] = 'http://'
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

  describe "#join" do
    before do
      @group = create_group
      @user = create_user
    end
    describe "未参加のユーザのみだった場合" do
      before do
        @group.join @user
      end
      it "参加されること" do
        @group.reload.users.should be_include(@user)
      end
    end
    describe "参加中のユーザだった場合" do
      before do
        @group.join @user
      end
      it "falseが返ること" do
        @group.join(@user).should == []
      end
    end
    describe "承認が必要なグループの場合" do
      before do
        @group.update_attribute(:protected, true)
      end
      it "オプションなしでは、参加待ちになること" do
        @group.join @user
        p = GroupParticipation.find_by_group_id_and_user_id(@group.id, @user.id)
        p.waiting.should be_true
      end
      it "強制参加オプションの場合" do
        @group.join @user, :force => true
        p = GroupParticipation.find_by_group_id_and_user_id(@group.id, @user.id)
        p.waiting.should be_false
      end
    end
    describe "参加済みのユーザの場合" do
      before do
        @group.join @user
      end
      it "オプションなしでは、失敗すること" do
        @group.join(@user).should == []
      end
      describe "複数ユーザが渡される場合" do
        describe "未参加のユーザと一緒に渡された場合" do
          before do
            @new_user = create_user
          end
          it "未参加のユーザが追加されること" do
            @group.join([@user,@new_user])
            GroupParticipation.find_by_group_id_and_user_id(@group.id, @new_user.id).should_not be_nil
          end
          it "参加済みのユーザは、追加登録されないこと" do
            @group.join([@user,@new_user])
            GroupParticipation.find_all_by_group_id_and_user_id(@group.id, @user.id).size.should == 1
          end
          it "エラーが設定されていること" do
            @group.join([@user,@new_user])
            @group.errors.should_not be_empty
          end
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
end
