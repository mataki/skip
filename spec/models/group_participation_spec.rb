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

describe GroupParticipation, '#group' do
  before do
    user = create_user
    @group = create_group
    @group_participation = GroupParticipation.create!(:user_id => user.id, :group_id => @group.id)
  end
  it '一件のグループが取得できること' do
    @group_participation.group.should_not be_nil
  end
  describe 'グループを論理削除された場合' do
    before do
      @group.logical_destroy
    end
    it 'グループが取得できないこと' do
      @group_participation.reload
      @group_participation.group.should be_nil
    end
  end
end

describe GroupParticipation, '#after_save' do
  before do
    @bob = create_user :user_options => {:name => 'ボブ', :admin => false}, :user_uid_options => {:uid => 'boob'}
    Group.record_timestamps = false
    @vim_group = create_group :name => 'Vim勉強会', :gid => 'vim_study', :updated_on => Time.now.yesterday, :created_on => Time.now.yesterday
    Group.record_timestamps = true
  end
  describe '参加待ちの場合' do
    it '所属するグループのupdate_onが変わらないこと' do
      before_updated_on = @vim_group.updated_on
      @vim_group.group_participations.create(:user_id => @bob.id, :waiting => true)
      @vim_group.reload
      before_updated_on.tv_sec.should == @vim_group.updated_on.tv_sec
    end
  end
  describe '参加中の場合' do
    it '所属するグループの更新日が更新されること' do
      before_updated_on = @vim_group.updated_on
      @vim_group.group_participations.create(:user_id => @bob.id, :waiting => false)
      @vim_group.reload
      before_updated_on.tv_sec.should_not == @vim_group.updated_on.tv_sec
    end
  end
end

describe GroupParticipation, '#after_destroy' do
  before do
    bob = create_user :user_options => {:name => 'ボブ', :admin => false}, :user_uid_options => {:uid => 'boob'}
    Group.record_timestamps = false
    @vim_group = create_group :name => 'Vim勉強会', :gid => 'vim_study' do |g|
      @group_participation = g.group_participations.build(:user_id => bob.id, :owned => true)
    end
    @vim_group.update_attributes(:updated_on => Time.now.yesterday, :created_on => Time.now.yesterday)
    Group.record_timestamps = true
  end
  it '所属するグループのupdated_onが更新されること' do
    before_updated_on = @vim_group.reload.updated_on
    @group_participation.destroy
    @vim_group.reload
    before_updated_on.tv_sec.should_not == @vim_group.updated_on.tv_sec
  end
end
