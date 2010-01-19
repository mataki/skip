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

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe Admin::BoardEntryCommentsController do
  before do
    admin_login

    @board_entry_comment = mock_model(Admin::BoardEntryComment, :topic_title => 'topic_title')

    @board_entry_comments = [@board_entry_comment]

    @board_entry_comments.stub!(:to_xml).and_return('XML')
    @board_entry_comments.stub!(:find).and_return(@board_entry_comment)

    @board_entry = mock_model(Admin::BoardEntry, :to_param => "1", :topic_title => 'topic_title')
    @board_entry.stub!(:board_entry_comments).and_return(@board_entry_comments)

    Admin::BoardEntry.stub!(:find).and_return(@board_entry)
  end
  describe "handling GET /admin_board_entry_comments" do
    def do_get
      get :index
    end

    it "should be successful" do
      do_get
      response.should be_success
    end

    it "should render index template" do
      do_get
      response.should render_template('index')
    end

    it "should find all admin_board_entry_comments" do
      @board_entry.should_receive(:board_entry_comments).and_return([@board_entry_comment])
      do_get
    end

    it "should assign the found admin_board_entry_comments for the view" do
      do_get
      assigns[:board_entry_comments].should == [@board_entry_comment]
    end
  end

  describe "handling GET /admin_board_entry_comments.xml" do
    def do_get
      @request.env["HTTP_ACCEPT"] = "application/xml"
      get :index
    end

    it "should be successful" do
      do_get
      response.should be_success
    end

    it "should find all admin_board_entry_comments" do
      @board_entry.should_receive(:board_entry_comments).and_return(@board_entry_comments)
      do_get
    end

    it "should render the found admin_board_entry_comments as xml" do
      @board_entry_comments.should_receive(:to_xml).and_return("XML")
      do_get
      response.body.should == "XML"
    end
  end

  describe "handling DELETE /admin_board_entry_comments/1" do
    before do
      @board_entry_comment.stub!(:destroy)
    end
    def do_delete
      delete :destroy, :id => "1"
    end

    it "should find the board_entry_comment requested" do
      @board_entry_comments.should_receive(:find).with("1").and_return(@board_entry_comment)
      do_delete
    end

    it "should call destroy on the found board_entry_comment" do
      @board_entry_comment.should_receive(:destroy)
      do_delete
    end

    it "should redirect to the admin_board_entry_comments list" do
      do_delete
      response.should redirect_to(admin_board_entry_board_entry_comments_path(@board_entry))
    end
  end
end

