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

describe Symbol, '.get_item_by_symbol' do
  describe '指定されたuidのユーザが見つかる場合' do
    before do
      create_user :user_uid_options => {:uid => 'skip'}
    end
    it '対象のUserが返ること' do
      Symbol.get_item_by_symbol('uid:skip').uid.should == 'skip'
    end
  end
  describe '指定されたuidのユーザが見つからない場合' do
    it 'nilが返ること' do
      Symbol.get_item_by_symbol('uid:skip').should be_nil
    end
  end
  describe '指定されたgidのグループが見つかる場合' do
    before do
      @group = create_group(:gid => 'skip_group')
    end
    it '対象のGroupが返ること' do
      Symbol.get_item_by_symbol('gid:skip_group').gid.should == 'skip_group'
    end
    describe '指定されたgidのグループが論理削除された場合' do
      before do
        @group.logical_destroy
      end
      it 'nilが返ること' do
        Symbol.get_item_by_symbol('gid:skip_group').should be_nil
      end
    end
  end
end


describe Symbol, '.items_by_partial_match_symbol_or_name' do
  describe '検索句が空の場合' do
    it '空配列が返ること' do
      Symbol.items_by_partial_match_symbol_or_name(nil).should be_empty
      Symbol.items_by_partial_match_symbol_or_name('').should be_empty
    end
  end
  describe '検索句がuid:で始まる場合' do
    describe '検索句に部分一致するログインIDのユーザが存在する場合' do
      before do
        @user = create_user(:user_uid_options => {:uid => 'master', :uid_type => 'MASTER'})
      end
      it '対象ユーザが取得できること' do
        Symbol.items_by_partial_match_symbol_or_name('uid:aste').should == [@user]
      end
    end
    describe '検索句に部分一致するユーザ名のユーザが存在する場合' do
      before do
        @user = create_user(:user_uid_options => {:uid => 'master', :uid_type => 'MASTER'})
        @user.user_uids.create!(:uid => 'nickname', :uid_type => 'NICKNAME')
      end
      it 'ログインIDで対象ユーザが取得できること' do
        Symbol.items_by_partial_match_symbol_or_name('uid:aste').should == [@user]
      end
      it 'ユーザ名で対象ユーザが取得できること' do
        Symbol.items_by_partial_match_symbol_or_name('uid:icknam').should == [@user]
      end
    end
  end
  describe '検索句がgid:で始まる場合' do
    describe '検索句に部分一致するgidのグループが存在する場合' do
      before do
        @group = create_group(:gid => 'vimgroup')
      end
      it '対象グループが取得できること' do
        Symbol.items_by_partial_match_symbol_or_name('gid:imgrou').should == [@group]
      end
      describe '対象のグループが論理削除された場合' do
        before do
          @group.logical_destroy
        end
        it '空配列が返ること' do
          Symbol.items_by_partial_match_symbol_or_name('gid:imgrou').should == []
        end
      end
    end
  end
  describe '検索句がuidやgidから始まらない場合' do
    describe '検索句に部分一致するユーザ名のユーザ及び、部分一致するgidのグループが存在する場合' do
      before do
        @user = create_user(:user_options => {:name => 'ユーザ'}, :user_uid_options => {:uid => 'master', :uid_type => 'MASTER'})
        @user.user_uids.create!(:uid => 'nickname', :uid_type => 'NICKNAME')
        @group = create_group(:gid => 'vimgroup', :name => 'VIMユーザグループ')
      end
      it '対象ユーザが取得できること' do
        Symbol.items_by_partial_match_symbol_or_name('aste').should == [@user]
      end
      it '対象グループが取得できること' do
        Symbol.items_by_partial_match_symbol_or_name('imgrou').should == [@group]
      end
      it '対象ユーザ及びグループが取得できること' do
        Symbol.items_by_partial_match_symbol_or_name('ユーザ').should == [@user, @group]
      end
    end
  end
end
