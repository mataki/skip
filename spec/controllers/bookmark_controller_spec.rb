# SKIP(Social Knowledge & Innovation Platform)
# Copyright (C) 2008-2009 TIS Inc.
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

describe BookmarkController do
  fixtures :bookmarks, :users, :user_uids
  before do
    user = user_login
    session[:user_id] = user.id
  end
  describe "必須項目の新規作成の場合" do
    it "レスポンスが成功であること" do
      post :update, {:bookmark => {:url => SkipFaker.url, :title => SkipFaker.rand_char},
                     :bookmark_comment => {:tags => '', :public => true, :comment => SkipFaker.rand_char },
                     :layout => 'dialog' }
      response.should be_success
    end
  end
  describe "全項目の新規作成の場合" do
    it "レスポンスが成功であること" do
      post :update, {:bookmark => {:url => SkipFaker.url, :title => SkipFaker.rand_char},
                     :bookmark_comment => {:tags => SkipFaker.tag, :public => true, :comment => SkipFaker.rand_char},
                     :layout => 'dialog' }
      response.should be_success
    end
  end
  describe "必須項目の更新の場合" do
    it "レスポンスが成功であること" do
      post :update, {:bookmark => {:url => @a_bookmark.url, :title => SkipFaker.rand_char},
                     :bookmark_comment => {:public => true, :comment => SkipFaker.rand_char}, :layout => 'dialog' }
      response.should be_success
    end
  end
  describe "全項目の更新の場合" do
    it "レスポンスが成功であること" do
      post :update, {:bookmark => {:url => @a_bookmark.url, :title => SkipFaker.rand_char},
                     :bookmark_comment => {:tags => SkipFaker.tag, :public => true, :comment => SkipFaker.rand_char},
                     :layout => 'dialog' }
      response.should be_success
    end
  end
end

describe BookmarkController, "GET #show" do
  before do
    user_login
  end
  describe "urlが送られていない場合" do
    before do
      Bookmark.should_receive(:find_by_url).with("", :include => :bookmark_comments).and_return(nil)
      get :show
    end
    it { response.should redirect_to(:controller => :mypage, :action => :index) }
    it "flashメッセージが設定されていること" do
      flash[:warn].should == "URL not bookmarked by anyone."
    end
  end
  describe "存在するブックマークがパラメータとして与えられた場合" do
    before do
      @url = "http://www.openskip.org/"
      @bookmark = mock_model(Bookmark, :title => "bookmark title", :url => @url)
      Bookmark.should_receive(:find_by_url).with(@url, :include => :bookmark_comments).and_return(@bookmark)

      get :show, :uri => @url
    end
    it { response.should render_template('bookmark/show') }
    it "正しいインスタンス変数が設定されていること" do
      assigns[:bookmark].should_not be_nil
      assigns[:main_menu].should_not be_nil
      assigns[:tab_menu_source].should_not be_nil
      assigns[:title].should_not be_nil
      assigns[:tags].should_not be_nil
      assigns[:create_button_show].should_not be_nil
    end
  end
end

describe BookmarkController, "GET #list" do
  before do
    @user = user_login
    controller.stub(:paginate).and_return([@pages = mock('pages'), @bookmark_comments = mock('bookmark_comments', :size => 10)])
    controller.stub(:user_tab_menu_source).and_return(@mock_tab_menu_source = mock('user_tab_menu_source'))
  end
  describe "自分のブックマーク一覧を表示した場合" do
    before do
      User.stub(:find_by_uid).with("a_user").and_return(@user)
      BookmarkComment.stub(:get_tags).with(@user.id).and_return(@tags = mock('tags'))
      get :list, :uid => "a_user"
    end
    it "set assigns" do
      assigns[:main_menu].should == "My Page"
      assigns[:title].should == "My Page"
      assigns[:tab_menu_source].should == @mock_tab_menu_source
      assigns[:tab_menu_option].should == { :uid => @user.uid }
      assigns[:tags].should == @tags
      assigns[:pages].should == @pages
      assigns[:bookmark_comments].should == @bookmark_comments
    end

    it { response.should render_template("list") }
  end

  describe "他人のブックマーク一覧を表示した場合" do
    before do
      User.stub(:find_by_uid).with("b_user").and_return(@target_user = mock_model(User, :name => "対象ユーザ", :uid => "b_user", :mark_track => true))
      BookmarkComment.stub(:get_tags).with(@target_user.id).and_return(@tags = mock('tags'))
      get :list, :uid => "b_user"
    end
    it "set assigns" do
      assigns[:main_menu].should == "Users"
      assigns[:title].should == "Mr./Ms. 対象ユーザ"
      assigns[:tab_menu_source].should == @mock_tab_menu_source
      assigns[:tab_menu_option].should == { :uid => @target_user.uid }
      assigns[:tags].should == @tags
      assigns[:pages].should == @pages
      assigns[:bookmark_comments].should == @bookmark_comments
    end

    it { response.should render_template("list") }
  end

#   describe "ユーザのブックマークを検索された場合" do
#     before do
#       @params = {:uid => "111111", :id => "uid:111111", :user_id => 1, :type => "page"}
#       @parent_controller.stub!(:params).and_return(@params)
#       controller.stub!(:parent_controller).and_return(@parent_controller)

#       get :list
#     end
#     it { response.should render_template('list') }
#   end

#   describe 'ユーザのブックマークの検索テキストボックスから検索された場合' do
#     before do
#       @params = {:uid => "admin", :id => "uid:admin", :user_id => 1, :keyword => "キーワード"}
#       @parent_controller.stub!(:params).and_return(@params)
#       controller.stub!(:parent_controller).and_return(@parent_controller)

#       get :list
#     end
#     it { response.should render_template('list') }
#   end
end

describe BookmarkController, "POST #destroy" do
  before do
    user_login

    @bookmark_comment = stub_model(BookmarkComment, :user_id => 1)

    BookmarkComment.stub!(:find).and_return(@bookmark_comment)
  end
  describe "bookmark_commentが存在する場合" do
    before do
      session[:user_id] = 1

      @bookmark = stub_model(Bookmark, :url => "http://www.openskip.org/")
      @bookmark_comment.should_receive(:destroy).and_return(@bookmark_comment)
      @bookmark_comment.stub!(:bookmark).and_return(@bookmark)

      post :destroy, :id => 1
    end
    it { response.should redirect_to(:action => :show, :uri => @bookmark.url ) }
    it "flashにメッセージが登録されていること" do
      flash[:notice] = '削除しました。'
    end
  end
  describe "削除権限がない場合" do
    before do
      session[:user_id] = 2

      post :destroy, :id => 1
    end
    it { response.should redirect_to(root_path) }
  end
end
