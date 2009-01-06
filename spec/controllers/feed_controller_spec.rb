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

describe FeedController, "#rss_feed" do
  before do
    @root_url = "root_url"
    controller.stub!(:root_url).and_return(@root_url)
    @url_for = "url_for"
    controller.stub!(:url_for).and_return(@url_for)
    @headers = {}
    controller.stub!(:headers).and_return(@headers)
    controller.stub!(:render)
  end
  describe "正しいパラメータが渡された場合" do
    it "RSSがレンダリングされること" do
      action_name = "recent_questions"
      description = "description"
      item_arry = [{:title => "title", :type => "page", :id => 1, :contents => "contents", :date => Time.now, :author => "author"}]

      controller.should_receive(:render)
      controller.send(:rss_feed, action_name, description, item_arry)
    end
  end
  if RUBY_VERSION >= '1.8.7' # 1.8.6系だとRSSのライブラリのバージョンが古いためRSS:NotSetErrorが発生せずにテストに失敗するので。
    describe "item_arryが空の場合" do
      it "空文字が返ること" do
        action_name = "recent_questions"
        description = "description"
        item_arry = []

        controller.should_receive(:render).with(:text => "", :layout => false)
        controller.send(:rss_feed, action_name, description, item_arry)
      end
    end
  end
end
