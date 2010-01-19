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

describe StatisticsController, "GET #index" do
  before do
    user_login

    @date = mock('date')

    @item_count = mock('item_count')
    controller.stub!(:get_site_count_hash_by_day).and_return(@item_count)
  end
  it "カレンダー表示用のHashが@item_countに設定されていること" do
    get :index
    assigns[:item_count].should == @item_count
  end

  describe "年月日のデータが渡された場合" do
    def get_statistics_with_date
      get :index, :year => "2008", :month => "10", :day => "3"
    end
    before do
      @date = mock('date')
      Date.stub!(:new).with(2008, 10, 3).and_return(@date)

      SiteCount.stub!(:get_by_date).and_return(nil)
    end
    it "@dateにパラメータから渡された年月日が入っていること" do
      get_statistics_with_date
      assigns[:date].should == @date
    end
    describe "データが見つかる場合" do
      before do
        @site_count = stub_model(SiteCount)
        SiteCount.should_receive(:get_by_date).with(@date).and_return(@site_count)

        get_statistics_with_date
      end
      it "statisticsがrenderされること" do
        response.should render_template('index')
      end
      it "該当するSiteCountが@site_countに設定されていること" do
        assigns[:site_count].should == @site_count
      end
    end
    describe "データが見つからない場合" do
      before do
        SiteCount.should_receive(:get_by_date).with(@date).and_return(nil)

        get_statistics_with_date
      end
      it "statisticsがrenderされること" do
        response.should render_template('index')
      end
      it "新規のSiteCountが@site_countに設定されていること" do
        assigns[:site_count].should be_new_record
      end
      it "flashにメッセージが設定されていること" do
        flash[:notice].should == 'Data not found.'
      end
    end
  end
  describe "パラメータが与えられない場合" do
    it "@dateにDate.todayが入っていること" do
      get :index
      assigns[:date].should == Date.today
    end
    describe "データが見つかる場合" do
      before do
        @site_count = stub_model(SiteCount)
        # applicationコントローラーで呼ばれるので２回になる
        SiteCount.should_receive(:find).twice.with(:first, :order => "created_on desc").and_return(@site_count)

        get :index
      end
      it "statisticsがrenderされること" do
        response.should render_template('index')
      end
      it "該当のSiteCountが@site_countに設定されていること" do
        assigns[:site_count].should == @site_count
      end
    end
    describe "データが見つからない場合" do
      before do
        SiteCount.should_receive(:find).twice.with(:first, :order => "created_on desc").and_return(nil)

        get :index
      end
      it "statisticsがrenderされること" do
        response.should render_template('index')
      end
      it "新規のSiteCountが@site_countに設定されていること" do
        assigns[:site_count].should be_new_record
      end
      it "flashにメッセージが設定されていること" do
        flash[:notice].should == 'Data not found.'
      end
    end
  end
end
