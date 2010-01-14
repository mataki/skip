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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe GroupCategory do
  describe GroupCategory, 'validation' do
    before do
      @group_category = valid_group_category
    end
    it 'codeが必須であること' do
      @group_category.code = ''
      @group_category.valid?.should be_false
    end
    it 'codeがユニークであること' do
      create_group_category(:code => 'SPORTS')
      @group_category.code = 'SPORTS'
      @group_category.valid?.should be_false
      # 大文字小文字が異なる場合もNG
      @group_category.code = 'Sports'
      @group_category.valid?.should be_false
    end
    it 'codeが20文字以下であること' do
      @group_category.code = SkipFaker.rand_alpha(21)
      @group_category.valid?.should be_false
      @group_category.code = SkipFaker.rand_alpha(20)
      @group_category.valid?.should be_true
    end
    it 'codeがアルファベットのみであること' do
      @group_category.code = 'aaa'
      @group_category.valid?.should be_true
      @group_category.code = 'AAA'
      @group_category.valid?.should be_true
      @group_category.code = 'aaa0'
      @group_category.valid?.should be_false
      @group_category.code = 'aaa+-\&^'
      @group_category.valid?.should be_false
    end

    it 'nameが必須であること' do
      @group_category.name = ''
      @group_category.valid?.should be_false
    end
    it 'nameが20文字以下であること' do
      @group_category.name = SkipFaker.rand_char(21)
      @group_category.valid?.should be_false
      @group_category.name = SkipFaker.rand_char(20)
      @group_category.valid?.should be_true
    end

    it 'iconが必須であること' do
      @group_category.icon = ''
      @group_category.valid?.should be_false
    end
    it 'iconがGroupCategory::ICONSに含まれること' do
      @group_category.icon = 'hoge'
      @group_category.valid?.should be_false
      @group_category.icon = 'ipod'
      @group_category.valid?.should be_true
    end

    it 'descriptionが255文字以下であること' do
      @group_category.description = SkipFaker.rand_char(256)
      @group_category.valid?.should be_false
      @group_category.description = SkipFaker.rand_char(255)
      @group_category.valid?.should be_true
    end
  end

  describe GroupCategory, '#before_save' do
    describe 'initial_selectedなレコードを保存する場合' do
      before do
        @new_group_category = valid_group_category
        @new_group_category.attributes = {:code => 'EMACS', :name => 'EMACS', :initial_selected => true}
      end
      describe 'まだinitial_selectedなレコードが存在しない場合' do
        it '正常に保存できること' do
          @new_group_category.save.should be_true
        end
      end
      describe 'initial_selectedなレコードが存在する場合' do
        before do
          @group_category = create_group_category(:code => 'VIM', :name => 'VIM', :initial_selected => true)
        end
        describe '新規登録の場合' do
          it '登録済みのGroupCategoryのinitial_selectedがfalseになること' do
            @new_group_category.save!
            @group_category.reload
            @group_category.initial_selected.should be_false
          end
        end
        describe '更新の場合' do
          before do
            # 事前にfalseで保存されている
            @new_group_category.initial_selected = false
            @new_group_category.save!
          end
          it '登録済みのGroupCategoryのinitial_selectedがfalseになること' do
            # trueに更新する
            @new_group_category.toggle!(:initial_selected)
            @group_category.reload
            @group_category.initial_selected.should be_false
          end
        end
      end
    end
  end

  describe GroupCategory, '#deletable?' do
    describe 'initial_selectedで既にグループが存在する場合' do
      before do
        # initial_selectedで、既にグループが存在している
        @vim_group_category = create_group_category(:code => 'VIM', :name => 'VIM', :initial_selected => true)
        @vim_group_category.groups << Admin::Group.new(:name => 'vim plugin', :description => 'vimpluginグループ', :gid => 'vimplugin')
      end
      it '削除不可と判定されること' do
        @vim_group_category.deletable?.should be_false
      end
      it 'エラーメッセージが設定されること' do
        lambda do
          @vim_group_category.deletable?
        end.should change(@vim_group_category.errors, :size).from(0).to(1)
      end
    end
    describe 'initial_selectedでまだグループが存在しない場合' do
      before do
        # initial_selectedで、まだグループが存在していない
        @net_beans_group_category = create_group_category(:code => 'NetBeans', :name => 'NetBeans', :initial_selected => true)
      end
      it '削除不可と判定されること' do
        @net_beans_group_category.deletable?.should be_false
      end
      it 'エラーメッセージが設定されること' do
        lambda do
          @net_beans_group_category.deletable?
        end.should change(@net_beans_group_category.errors, :size).from(0).to(1)
      end
    end

    describe 'initial_selectedではなく、既にグループが存在する場合' do
      before do
        # initial_selectedじゃなく、既にグループが存在している
        @emacs_group_category = create_group_category(:code => 'EMACS', :name => 'EMACS', :initial_selected => false)
        @emacs_group_category.groups << Admin::Group.new(:name => 'emacs lisp', :description => 'emacs lispグループ', :gid => 'emacslisp')
      end
      it '削除不可と判定されること' do
        @emacs_group_category.deletable?.should be_false
      end
      it 'エラーメッセージが設定されること' do
        lambda do
          @emacs_group_category.deletable?
        end.should change(@emacs_group_category.errors, :size).from(0).to(1)
      end
    end
    describe 'initial_selectedではなく、まだグループが存在しない場合' do
      before do
        # initial_selectedじゃなく、まだグループが存在しない
        @eclipse_group_category = create_group_category(:code => 'ECLIPSE', :name => 'ECLIPSE', :initial_selected => false)
      end
      it '削除可と判定されること' do
        @eclipse_group_category.deletable?.should be_true
      end
    end
  end
end

describe GroupCategory, '#groups' do
  before do
    @group_category = create_group_category
    @group_category.groups.create!(:name => 'name', :description => 'description', :gid => 'ggid')
  end
  it '一件のグループが取得できること' do
    @group_category.groups.size.should == 1
  end
  describe 'グループを論理削除された場合' do
    before do
      @group_category.groups.first.logical_destroy
      @group_category.reload
    end
    it 'グループが取得できないこと' do
      @group_category.groups.size.should == 0
    end
  end
end

describe GroupCategory, ".with_groups_count" do
  before do
    @gc = (1..2).map{|i| icon = GroupCategory::ICONS.rand;GroupCategory.create!(:name => "name#{i}", :code => SkipFaker.rand_alpha, :icon => icon) }
    @gc[0].groups << @groups1 = (1..4).map{ |i| create_group(:gid => "group1#{i}") }
    @gc[1].groups << @groups2 = create_group(:gid => "group2")
  end
  describe "userの条件がない場合" do
    before do
      @gc_wgc = GroupCategory.with_groups_count(nil).all
    end
    it "group_categoryが全件が取れること" do
      @gc_wgc.size.should == GroupCategory.count
    end
    it "countが正しく取れること" do
      @gc_wgc[0].count.should == "0"
      @gc_wgc[1].count.should == @groups1.size.to_s
      @gc_wgc[2].count.should == "1"
    end
  end
  describe "userの条件がある場合" do
    before do
      @user = create_user
      GroupParticipation.create!(:group => @groups2, :user => @user)
      GroupParticipation.create!(:group => @groups1[0], :user => @user)
      @gc_wgc = GroupCategory.with_groups_count(@user).all
    end
    it "GroupCategoryが取れること" do
      @gc_wgc.size.should == 2
    end
    # 本当は、これでCategory全件と、所属件数を纏めて全てとりたかったんだけどだめだった。
#     it "group_categoryが全件が取れること" do
#       @gc_wgc.size.should == GroupCategory.count
#     end
#     it "countが正しく取れること" do
#       @gc_wgc[0].count.should == "0"
#       @gc_wgc[1].count.should == "1"
#       @gc_wgc[2].count.should == "1"
#     end
  end
end
