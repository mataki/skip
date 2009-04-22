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
