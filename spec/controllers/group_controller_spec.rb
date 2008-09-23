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

describe GroupController, "POST #destroy" do
  before do
    user_login

    @group_participation = stub_model(GroupParticipation)
    @group_participation.stub!(:owned?).and_return(true)

    @group_participations = mock('group_participations')
    @group_participations.stub!(:find_by_user_id).and_return(@group_participation)

    @group = stub_model(Group)
    @group.stub!(:group_participations).and_return(@group_participations)
    Group.stub!(:find_by_gid).and_return(@group)
  end
  describe "グループにユーザが存在している場合" do
    before do
      @group_participations.should_receive(:size).and_return(2)

      post :destroy
    end
    it "showにリダイレクトされる" do
      response.should redirect_to(:action => "show")
    end
    it "flashにメッセージが登録されている" do
      flash[:warning].should == '自分以外のユーザがまだ存在しています。削除できません。'
    end
  end
  describe "削除される場合" do
    before do
      @group_participations.should_receive(:size).and_return(1)

      @group.should_receive(:destroy).and_return(true)

      post :destroy
    end
    it "グループにリダイレクトされる" do
      response.should redirect_to(:controller => "groups")
    end
    it "flashにメッセージが登録されている" do
      flash[:notice].should == 'グループは削除されました。'
    end
  end
end

describe GroupController, "POST #leave" do
  before do
    user_login

    @group_participation = stub_model(GroupParticipation)

    @group_participations = mock('group_participations')

    @group = stub_model(Group)
    @group.stub!(:group_participations).and_return(@group_participations)

    Group.stub!(:find_by_gid).and_return(@group)
  end
  describe "参加している場合" do
    before do
      @group_participation.should_receive(:destroy).and_return(@group_participation)
      @group_participations.stub!(:find_by_user_id).and_return(@group_participation)

      login_user_groups = mock('login_user_groups')
      login_user_groups.should_receive(:delete)
      controller.should_receive(:login_user_groups).and_return(login_user_groups)

      post :leave
    end
    it { response.should redirect_to(:action => :show) }
    it "flashにメッセージが登録されていること" do
      flash[:notice].should == '退会しました。'
    end
  end
  describe "参加していない場合" do
    before do
      @group_participations.stub!(:find_by_user_id).and_return(nil)

      post :leave
    end
    it { response.should redirect_to(:action => :show) }
    it "flashにメッセージが登録されていること" do
      flash[:notice].should == 'そのグループには参加していません。'
    end
  end
end
