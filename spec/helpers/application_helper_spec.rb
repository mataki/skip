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

describe ApplicationHelper, "#show_contents" do
  describe "hikiモードの時" do
    before do
      @entry = stub_model(BoardEntry, :editor_mode => 'hiki', :contents => "hogehoge",
                          :symbol => "uid:hoge", :user_id => 1)
      @output_contents = "output_contents {{question.gif,240,}} output_contents"
      helper.stub!(:hiki_parse).and_return(@output_contents)
      helper.stub!(:parse_hiki_embed_syntax).and_return(@output_contents)

      @result = helper.show_contents(@entry)
    end
    it { @result.should have_tag("div.hiki_style") }
    it { @result.should be_include('output_contents') }
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
  end
  describe '現在のページを表示している場合' do
    before do
      helper.stub!(:current_page?).and_return(true)
      expected_link_tag = '<a href="/controller/action" class="selected"><span>label</span></a>'
      @expected_html = content_tag(:ul, content_tag(:li, expected_link_tag))
    end
    it 'aタグのclassにselectedが含まれていること' do
      tab_menu_sources = [{:label => @label, :options => {:controller => 'controller', :action => @action}}]
      helper.generate_tab_menu(tab_menu_sources).should == @expected_html
    end
  end
  describe '現在のページを表示している場合' do
    before do
      helper.stub!(:current_page?).and_return(false)
      expected_link_tag = '<a href="/controller/action"><span>label</span></a>'
      @expected_html = content_tag(:ul, content_tag(:li, expected_link_tag))
    end
    it 'aタグのclassにselectedが含まれていること' do
      tab_menu_sources = [{:label => @label, :options => {:controller => 'controller', :action => @action}}]
      helper.generate_tab_menu(tab_menu_sources).should == @expected_html
    end
  end
end

describe ApplicationHelper, '#user_link_to_with_portrait' do
  before do
    @user = stub_model(User, :uid => 'uid:skipkuma', :name => 'skipkuma')
    @url_params = {:controller => '/user', :action => 'show', :uid => @user.uid}
    @mock_picture = mock('picture')
  end
  describe 'width, heightの指定がない場合' do
    it 'width 80, height 80 のポートレイト画像付きユーザリンクが生成されること' do
      helper.should_receive(:show_picture).with(@user, :width => 80, :height => 80).and_return(@mock_picture)
      helper.should_receive(:link_to).with(@mock_picture, @url_params, anything())
      helper.user_link_to_with_portrait(@user)
    end
  end
  describe 'width 60, height 40の指定がある場合' do
    before do
      it 'width 60, height 40 のポートレイト画像付きユーザリンクが生成されること' do
        helper.should_receive(:show_picture).with(@user, :width => 60, :height => 40).and_return(@mock_picture)
        helper.should_receive(:link_to).with(@mock_picture, @url_params, anything())
        helper.user_link_to_with_portrait(@user)
      end
    end
  end
end

describe ApplicationHelper, "#get_entry_infos" do
  it "要素が一つもないときは、空白になること" do
    entry = mock_model(BoardEntry)
    entry.stub(:board_entry_comments_count).and_return(0)
    entry.stub(:point).and_return(0)
    entry.stub(:entry_trackbacks_count).and_return(0)
    entry.stub_chain(:state, :access_count).and_return(0)
    helper.get_entry_infos(entry).should == '&nbsp;'
  end
  it "全ての要素が1の場合、-で連結されること" do
    entry = mock_model(BoardEntry)
    entry.stub(:board_entry_comments_count).and_return(1)
    entry.stub(:point).and_return(1)
    entry.stub(:entry_trackbacks_count).and_return(1)
    entry.stub_chain(:state, :access_count).and_return(1)
    helper.get_entry_infos(entry).should == "Comment(1)-GoodJob(1)-Trackback(1)-Access(1)"
  end
end
