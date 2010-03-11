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

describe BoardEntriesHelper, '.link_to_write_place' do
  before do
    @owner = mock('')
  end
  describe 'リンクの文言が取得できる場合' do
    before do
      @link_name = 'link_name'
      helper.should_receive(:write_place_name).and_return(@link_name)
      @link_url = 'link_url'
      helper.should_receive(:write_place_url).and_return(@link_url)
    end
    it 'URLが生成されること' do
      helper.should_receive(:link_to).with(@link_name, @link_url)
      helper.link_to_write_place(@owner)
    end
  end
  describe 'リンクの文言が取得できない場合' do
    before do
      helper.should_receive(:write_place_name).and_return('')
    end
    it '空文字が返却されること' do
      helper.link_to_write_place(@owner).should == ''
    end
  end
end

describe BoardEntriesHelper, '#write_place_name' do
  describe '引数のownerがnilの場合' do
    it { helper.write_place_name(nil) == '' }
  end
  describe '引数のownerがnil以外の場合' do
    describe 'ownerの型がUserの場合' do
      before do
        @owner = mock_model(User, :name => 'ユーザ', :uid => SkipFaker.rand_char)
      end
      it '「ユーザのブログ」という文言が返却されること' do
        helper.write_place_name(@owner).should == "#{h @owner.name}'s Blog"
      end
    end
    describe 'ownerの型がGroupの場合' do
      before do
        @owner = mock_model(Group, :name => 'グループ', :gid => SkipFaker.rand_char)
      end
      it '「グループのフォーラム」という文言が返却されること' do
        helper.write_place_name(@owner).should == "Forums of #{h @owner.name}"
      end
    end
    describe 'ownerの型が不明な場合' do
      # 通常のフローではありえないはず。
      before do
        @owner = mock('')
      end
      it '空文字が返却されること' do
        helper.write_place_name(@owner).should == ''
      end
    end
  end
end

describe BoardEntriesHelper, "#icon_with_information" do
  before do
    @user = mock('User',:id => 1)
  end
  describe "12時間以内の場合" do
    before do
      @comment = stub_model(BoardEntryComment, :created_on => 10.hour.ago, :updated_on => 8.hour.ago, :id => 1)
      helper.stub!(:icon_tag).with(:emoticon_happy)
    end
    describe "未読の場合(過去にチェック済み)" do
      before do
        @checked_on = 10.hour.ago
      end
      it "emoticon_happyのアイコンを含むこと" do
        helper.should_receive(:icon_tag).with(:emoticon_happy)
        helper.icon_with_information(@user, @comment, @checked_on)
      end
      it "未読が含まれること" do
        helper.icon_with_information(@user, @comment, @checked_on).should be_include("[Unread]")
      end
      it "新着が含まれること" do
        helper.icon_with_information(@user, @comment, @checked_on).should be_include("[New]")
      end
    end
    describe "未読の場合(記事を参照したことがない)" do
      before do
        @checked_on = nil
      end
      it "emoticon_happyのアイコンを含むこと" do
        helper.should_receive(:icon_tag).with(:emoticon_happy)
        helper.icon_with_information(@user, @comment, @checked_on)
      end
      it "未読が含まれること" do
        helper.icon_with_information(@user, @comment, @checked_on).should be_include("[Unread]")
      end
      it "新着が含まれること" do
        helper.icon_with_information(@user, @comment, @checked_on).should be_include("[New]")
      end
    end
    describe "未読でない場合" do
      before do
        @checked_on = 6.hour.ago
      end
      it "emoticon_happyのアイコンを含むこと" do
        helper.should_receive(:icon_tag).with(:emoticon_happy)
        helper.icon_with_information(@user, @comment, @checked_on)
      end
      it "未読が含まれないこと" do
        helper.icon_with_information(@user, @comment, @checked_on).should_not be_include("[Unread]")
      end
      it "新着が含まれること" do
        helper.icon_with_information(@user, @comment, @checked_on).should be_include("[New]")
      end
    end
  end
  describe "24時間以内の場合" do
    before do
      @comment = stub_model(BoardEntryComment, :created_on => 16.hour.ago, :updated_on => 8.hour.ago, :id => 1)
      helper.stub!(:icon_tag).with(:emoticon_smile)
    end
    describe "未読の場合" do
      before do
        @checked_on = 10.hour.ago
      end
      it "emoticon_smileのアイコンを含むこと" do
        helper.should_receive(:icon_tag).with(:emoticon_smile)
        helper.icon_with_information(@user, @comment, @checked_on)
      end
      it "未読が含まれること" do
        helper.icon_with_information(@user, @comment, @checked_on).should be_include("[Unread]")
      end
      it "新着が含まれること" do
        helper.icon_with_information(@user, @comment, @checked_on).should be_include("[New]")
      end
    end
    describe "未読でない場合" do
      before do
        @checked_on = 6.hour.ago
      end
      it "emoticon_smileのアイコンが含まれること" do
        helper.should_receive(:icon_tag).with(:emoticon_smile)
        helper.icon_with_information(@user, @comment, @checked_on)
      end
      it "未読が含まれないこと" do
        helper.icon_with_information(@user, @comment, @checked_on).should_not be_include("[Unread]")
      end
      it "新着が含まれること" do
        helper.icon_with_information(@user, @comment, @checked_on).should be_include("[New]")
      end
    end
  end
  describe "24時間をすぎている場合" do
    before do
      @comment = stub_model(BoardEntryComment, :created_on => 30.hour.ago, :updated_on => 8.hour.ago, :id => 1)
      helper.stub!(:icon_tag).with(:emoticon_smile)
    end
    describe "未読の場合" do
      before do
        @checked_on = 10.hour.ago
      end
      it "emoticon_smileのアイコンを含むこと" do
        helper.should_receive(:icon_tag).with(:emoticon_smile)
        helper.icon_with_information(@user, @comment, @checked_on)
      end
      it "未読が含まれること" do
        helper.icon_with_information(@user, @comment, @checked_on).should be_include("[Unread]")
      end
      it "新着が含まれないこと" do
        helper.icon_with_information(@user, @comment, @checked_on).should_not be_include("[New]")
      end
    end
    describe "未読でない場合" do
      before do
        @checked_on = 6.hour.ago
      end
      it "emoticon_smileのアイコンが含まれないこと" do
        helper.should_not_receive(:icon_tag)
        helper.icon_with_information(@user, @comment, @checked_on)
      end
      it "未読が含まれないこと" do
        helper.icon_with_information(@user, @comment, @checked_on).should_not be_include("[Unread]")
      end
      it "新着が含まれないこと" do
        helper.icon_with_information(@user, @comment, @checked_on).should_not be_include("[New]")
      end
    end
  end
end

describe BoardEntriesHelper, "#show_contents" do
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

