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

describe GroupsController do
  before do
    user_login
  end
  describe "#index" do
    describe "グループが存在した場合" do
      before do
        @groups = [stub_model(Group)]
        Group.should_receive(:paginate).and_return(@groups)
        get :index
      end

      it { response.should be_success }
      it { assigns[:pages].should == @pages }
      it { assigns[:groups].should == @groups }
    end
    describe "グループが存在しなかった場合" do
      before do
        Group.should_receive(:paginate).and_return([])
        stub_flash_now
        get :index
      end

      it { response.should be_success }
      it { flash[:notice].should_not be_nil }
    end
  end
end

describe GroupsController, "GET #new" do
  before do
    user_login

    @group = stub_model(Group)
    Group.stub!(:new).and_return(@group)

    @group_categories = (1..3).map{|i| stub_model(GroupCategory)}
    GroupCategory.stub!(:all).and_return(@group_categories)

    get :new
  end
  it { response.should render_template("new") }
end

describe GroupsController, "POST #create" do
  before do
    user_login

    @group = mock_model(Group, :gid => "gid", :name => "name", :group_category_id => 1, :description => "description", :protected => true)
    Group.stub!(:new).and_return(@group)

    @group_categories = (1..3).map{|i| stub_model(GroupCategory)}
    GroupCategory.stub!(:all).and_return(@group_categories)

    @group_participation = mock_model(GroupParticipation)
    @group_participations = mock('group_participations')
    @group_participations.stub!(:build).and_return(@group_participation)
    @group.stub!(:group_participations).and_return(@group_participations)
  end
  describe "保存に成功する場合" do
    before do
      @group.should_receive(:save).and_return(true)

      post :create
    end
    it { response.should redirect_to(:controller => "group", :action => "show", :gid => @group.gid) }
    it "flashにメッセージが登録されていること" do
      flash[:notice].should == 'Group was created successfully.'
    end
  end
  describe "保存に失敗する場合" do
    before do
      @group.should_receive(:save).and_return(false)
      @group.stub!(:errors).and_return([])

      post :create
    end
    it { response.should render_template("new") }
  end
end

