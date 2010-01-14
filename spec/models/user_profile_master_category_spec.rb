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

describe UserProfileMasterCategory do
  describe UserProfileMasterCategory, '#deletable?' do
    describe 'このカテゴリに紐付くプロフィール項目が登録されている場合' do
      before do
        @user_profile_master_category = create_user_profile_master_category(:name => '業務')
        @user_profile_master_category.user_profile_masters << UserProfileMaster.new(:name => '自己紹介', :input_type => 'richtext')
      end
      it '削除不可と判定されること' do
        @user_profile_master_category.deletable?.should be_false
      end
      it 'エラーメッセージが設定されること' do
        lambda do
          @user_profile_master_category.deletable?
        end.should change(@user_profile_master_category.errors, :size).from(0).to(1)
      end
    end
    describe 'このカテゴリに紐付くプロフィール項目が登録されていない場合' do
      before do
        @user_profile_master_category = create_user_profile_master_category(:name => 'プライベート')
      end
      it '削除可と判定されること' do
        @user_profile_master_category.deletable?.should be_true
      end
    end
  end
end
