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

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe Admin::UserProfileMastersController, 'GET /index' do
  describe 'プロフィールカテゴリが2件存在する場合' do
    before do
      @basic_info = create_user_profile_master_category(:name => '基本情報', :sort_order => 0)
      @extra_info = create_user_profile_master_category(:name => '追加情報', :sort_order => 1)
      admin_login
    end
    describe '各々のプロフィールカテゴリに紐付くプロフィールマスタが2件ずつ存在する場合' do
      before do
        @introduction = create_user_profile_master(:user_profile_master_category_id => @basic_info.id, :name => '自己紹介', :input_type => 'richtext', :sort_order => 1)
        @birthday = create_user_profile_master(:user_profile_master_category_id => @basic_info.id, :name => '誕生日', :input_type => 'datepicker', :sort_order => 0)
        @hobby = create_user_profile_master(:user_profile_master_category_id => @extra_info.id, :name => '趣味', :input_type => 'checkbox', :sort_order => 1)
        @off = create_user_profile_master(:user_profile_master_category_id => @extra_info.id, :name => 'オフの私', :input_type => 'richtext')
      end
      it 'プロフィール一覧が設定されていること' do
        get :index
        assigns[:user_profile_masters].should_not be_nil
      end
      it 'プロフィール一覧がプロフィールカテゴリの昇順かつ、プロフィールマスタの昇順に並んでいること' do
        get :index
        assigns[:user_profile_masters].map(&:id).should == [@birthday.id, @introduction.id, @off.id, @hobby.id]
      end
    end
  end
end
