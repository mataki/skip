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

describe ApplicationHelper, "#show_contents" do
  describe "hikiモードの時" do
    before do
      @entry = stub_model(BoardEntry, :editor_mode => 'hiki', :contents => "hogehoge",
                          :symbol => "uid:hoge", :user_id => 1)
      @output_contents = "output_contents {{question.gif,240,}} output_contents"
      helper.stub!(:hiki_parse).and_return(@output_contents)

      @result = helper.show_contents(@entry)
    end
    it { @result.should have_tag("div.hiki_style") }
    it { @result.should be_include('output_contents') }
    it { @result.should be_include("/user/hoge/files/question.gif") }
  end
end

describe ApplicationHelper, '#file_link_url' do
  describe '第一引数がShareFileのインスタンスの場合' do
    before do
      @share_file = stub_model(ShareFile, :owner_symbol => 'uid:foo', :file_name => 'bar.jpg')
    end
    it 'share_file_urlが正しいパラメタで呼ばれること' do
      helper.should_receive(:share_file_url).with(:controller_name => 'user', :symbol_id => 'foo', :file_name => 'bar.jpg')
      helper.file_link_url(@share_file)
    end
  end
  describe '第一引数がHashの場合' do
    before do
      @share_file_hash = {:owner_symbol => 'uid:foo', :file_name => 'bar.jpg'}
    end
    it 'share_file_urlが正しいパラメタで呼ばれること' do
      helper.should_receive(:share_file_url).with(:controller_name => 'user', :symbol_id => 'foo', :file_name => 'bar.jpg')
      helper.file_link_url(@share_file_hash)
    end
  end
end

describe ApplicationHelper, '#generate_tab_menu' do
  before do
    @action = 'action'
    @label = 'label'
    @controller = mock('controller')
    helper.stub!(:controller).and_return(@controller)
  end
  describe 'selected_actionsが指定されている場合' do
    before do
      @selected_actions = ['selected_action']
    end
    describe 'controllerのactionがselected_actionsに含まれる場合' do
      before do
        @controller.stub!(:action_name).and_return('selected_action')
        expected_link_tag = '<a href="/controller/action" class="selected"><span>label</span></a>'
        @expected_html = content_tag(:ul, content_tag(:li, expected_link_tag))
      end
      it 'html_options[:class]にselectedが含まれること' do
        tab_menu_sources = [{:label => @label, :options => {:controller => 'controller', :action => @action}, :selected_actions => @selected_actions}]
        helper.generate_tab_menu(tab_menu_sources).should == @expected_html
      end
    end
    describe 'controllerのactionがselected_actionsに含まれない場合' do
      before do
        @controller.stub!(:action_name).and_return('not_selected_action')
        expected_link_tag = '<a href="/controller/action"><span>label</span></a>'
        @expected_html = content_tag(:ul, content_tag(:li, expected_link_tag))
      end
      it 'html_options[:class]にselectedが含まれないこと' do
        tab_menu_sources = [{:label => @label, :options => {:controller => 'controller', :action => @action}, :selected_actions => @selected_actions}]
        helper.generate_tab_menu(tab_menu_sources).should == @expected_html
      end
    end
  end
  describe 'selected_actionsが指定されていない場合' do
    before do
      @selected_actions = nil
    end
    describe 'controllerのactionがoptions[:action]と等しい場合' do
      before do
        @controller.stub!(:action_name).and_return(@action)
        expected_link_tag = '<a href="/controller/action" class="selected"><span>label</span></a>'
        @expected_html = content_tag(:ul, content_tag(:li, expected_link_tag))
      end
      it 'aタグのclassにselectedが含まれていること' do
        tab_menu_sources = [{:label => @label, :options => {:controller => 'controller', :action => @action}, :selected_actions => @selected_actions}]
        helper.generate_tab_menu(tab_menu_sources).should == @expected_html
      end
    end
    describe 'controllerのactionがoptions[:action]と等しくない場合' do
      before do
        @controller.stub!(:action_name).and_return('hoge')
        expected_link_tag = '<a href="/controller/action"><span>label</span></a>'
        @expected_html = content_tag(:ul, content_tag(:li, expected_link_tag))
      end
      it 'aタグのclassにselectedが含まれていること' do
        tab_menu_sources = [{:label => @label, :options => {:controller => 'controller', :action => @action}, :selected_actions => @selected_actions}]
        helper.generate_tab_menu(tab_menu_sources).should == @expected_html
      end
    end
  end
end

describe ApplicationHelper, '#user_link_to_with_portrait' do
  before do
    @user = stub_model(User, :uid => 'uid:skipkuma', :name => 'skipkuma')
    @url_params = {:controller => 'user', :action => 'show', :uid => @user.uid}
    @mock_picture = mock('picture')
  end
  describe 'width, heightの指定がない場合' do
    it 'width 120, height 80 のポートレイト画像付きユーザリンクが生成されること' do
      helper.should_receive(:showPicture).with(@user, 120, 80).and_return(@mock_picture)
      helper.should_receive(:link_to).with(@mock_picture, @url_params, anything())
      helper.user_link_to_with_portrait(@user)
    end
  end
  describe 'width 60, height 40の指定がある場合' do
    before do
      it 'width 60, height 40 のポートレイト画像付きユーザリンクが生成されること' do
        helper.should_receive(:showPicture).with(@user, 60, 40).and_return(@mock_picture)
        helper.should_receive(:link_to).with(@mock_picture, @url_params, anything())
        helper.user_link_to_with_portrait(@user)
      end
    end
  end
end

describe ApplicationHelper, "#get_menu_items" do
  before do
    @menus = [{ :name => "name1", :menu => "menu1"}, { :name => "name2", :menu => "menu2"}]
    request.path_parameters = { :controller => "mypage" }
  end
  it "menu1が選択されている場合 menu2にはリンクが含まれていること" do
    ar = helper.get_menu_items(@menus, "menu1", "action")
    ar.first.should have_tag("b", "name1")
    ar.first.should_not have_tag("a", "name1")
    ar.last.should have_tag("a[href=/mypage/action?menu=menu2]", "name2")
    ar.last.should_not have_tag("b", "name2")
  end
  it "menu2が選択されている場合 menu1にはリンクが含まれていること" do
    ar = helper.get_menu_items(@menus, "menu2", "action")
    ar.first.should_not have_tag("b", "name1")
    ar.first.should have_tag("a[href=/mypage/action?menu=menu1]", "name1")
    ar.last.should_not have_tag("a", "name2")
    ar.last.should have_tag("b", "name2")
  end
  describe "@menusの中にurlパラメータを含める場合" do
    before do
      @menus.each do |menu|
        menu[:url] = { :action => menu[:menu], :controller => "mypage" }
      end
    end
    it "menu1が選択されている場合 menu2にはurlのパラメータを利用したリンクが含まれていること" do
      ar = helper.get_menu_items(@menus, "menu1", "action")
    ar.last.should have_tag("a[href=/mypage/menu2]", "name2")
    end
  end
end

describe ApplicationHelper, '#url_for_bookmark' do
  before do
    @bookmark = Bookmark.new :url => 'http://b.hatena.ne.jp/search?ie=utf8&q=vim+エディタ&x=0&y=0'
  end
  it '正しいURLが生成されること' do
    helper.url_for_bookmark(@bookmark).should == '/bookmark/show/http:%2F%2Fb.hatena.ne.jp%2Fsearch%3Fie=utf8&amp;q=vim+%25E3%2582%25A8%25E3%2583%2587%25E3%2582%25A3%25E3%2582%25BF&amp;x=0&amp;y=0'
  end
end

describe ApplicationHelper, '#link_to_bookmark_url' do
  before do
    helper.stub!(:relative_url_root).and_return('')
    @bookmark = stub_model(Bookmark)
  end
  describe '対象のブックマークが記事の場合' do
    before do
      @bookmark.url = '/page/99'
    end
    it '記事へのリンクとなること' do
      helper.send!(:link_to_bookmark_url, @bookmark).include?('report_link').should be_true
    end
  end
  describe '対象のブックマークがユーザの場合' do
    before do
      @bookmark.url = '/user/99'
    end
    it 'ユーザへのリンクとなること' do
      helper.send!(:link_to_bookmark_url, @bookmark).include?('user').should be_true
    end
  end
  describe '対象のブックマークがwwwの場合' do
    before do
      @bookmark.url = 'http://localhost'
    end
    it 'wwwへのリンクとなること' do
      helper.send!(:link_to_bookmark_url, @bookmark).include?('world_link').should be_true
    end
  end
  describe 'titleが指定されている場合' do
    before do
      @bookmark.url = 'http://localhost'
    end
    it '指定されたタイトルになること' do
      helper.send!(:link_to_bookmark_url, @bookmark, 'skip_user_group').include?('skip_user_group').should be_true
    end
  end
  describe 'titleが指定されていない場合' do
    before do
      @bookmark.url = 'http://localhost'
      @bookmark.title = 'world_wide_web'
    end
    it '登録済みのタイトルになること' do
      helper.send!(:link_to_bookmark_url, @bookmark).include?('world_wide_web').should be_true
    end
  end
end
