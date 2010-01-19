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

describe BookmarkComment do
  describe "#validate" do
    it "Tagにエラーがある場合、エラーが設定されている" do
      errors = (1..3).map{ |i| mock("error #{i}")}
      Tag.should_receive(:validate_tags).at_least(:once).and_return(errors)
      bc = BookmarkComment.new
      bc.should_not be_valid
    end
  end

  describe "#after_save" do
    it "保存するとき、タグが一緒に保存される" do
      Tag.should_receive(:create_by_comma_tags)
      # TODO 下のように初期値がないとMysqlのインサートエラーが起こる
      bc = BookmarkComment.new :public => true ,:bookmark_id => 1, :user_id => 1, :comment => ""
      bc.save
    end
  end

  describe ".make_conditions_for_tag" do
    it "for_tagがtrueでmake_conditions_tag_or_commentが呼ばれること" do
      login_user_id = 1
      options = {:hoge => "hoge"}
      BookmarkComment.should_receive(:make_conditions_tag_or_comment).with(login_user_id, true, options)
      BookmarkComment.make_conditions_for_tag(login_user_id, options)
    end
  end

  describe ".make_conditions_for_comment" do
    it "for_tagがfalseでmake_conditions_tag_or_commentが呼ばれること" do
      login_user_id = 1
      options = {:hoge => "hoge"}
      BookmarkComment.should_receive(:make_conditions_tag_or_comment).with(login_user_id, false, options)
      BookmarkComment.make_conditions_for_comment(login_user_id, options)
    end
  end

  describe ".get_tag_words" do
    before do
      @tags1 = (1..2).map{|i| mock_model(BookmarkCommentTag)}
      @tags1[0].stub!(:name).and_return("a")
      @tags1[1].stub!(:name).and_return("b")
      @tags2 = (1..2).map{|i| mock_model(BookmarkCommentTag)}
      @tags2[0].stub!(:name).and_return("b")
      @tags2[1].stub!(:name).and_return("c")
      @bcs = (1..2).map{|i| mock_model(BookmarkComment)}
      @bcs[0].should_receive(:tag_strings).and_return(@tags1)
      @bcs[1].should_receive(:tag_strings).and_return(@tags2)
    end

    describe "引数にtagのconditionsが設定されている場合" do
      before do
        @conditions_for_tag = ["hoge =　?",1]
        options = {:order => 'tags.name', :include => [:tag_strings], :conditions => @conditions_for_tag}
        BookmarkComment.should_receive(:find).with(:all, options).and_return(@bcs)

        @result = BookmarkComment.get_tag_words @conditions_for_tag
      end
      it "findの引数にconditionsが設定されていること" do
      end

      it "タグがユニークな状態で帰ってくること" do
        @result.size.should == 3
      end
    end

    describe "引数にtagのconditionsが設定されていない場合" do
      before do
        options = {:order => 'tags.name', :include => [:tag_strings]}
        BookmarkComment.should_receive(:find).with(:all, options).and_return(@bcs)
        @result = BookmarkComment.get_tag_words
      end
      it "findの引数にconditionsが設定されていないこと" do
      end
      it "タグがユニークな状態で帰ってくること" do
        @result.size.should == 3
      end
    end
  end

  describe ".get_tags_hash" do
    before do
      @tags = (1..4).map{|i| mock_model(BookmarkComment)}
      login_user_id = 1
      BookmarkComment.should_receive(:get_tag_words).with(["user_id = ?", login_user_id]).and_return(@tags[0..2])
      Tag.should_receive(:get_standard_tags).and_return([@tags[0]])
      BookmarkComment.should_receive(:get_tag_words).and_return(@tags)
      @tags_hash = BookmarkComment.get_tags_hash login_user_id
    end
    it { @tags_hash[:standard].should == [@tags[0]] }
    it { @tags_hash[:mine].should == [@tags[1], @tags[2]] }
    it { @tags_hash[:user].should == [@tags[3]] }
  end

  describe ".get_popular_tag_words" do
    it "タグが最大20個返ってくること" do
      tags = (1..30).map{|i| mock_model(BookmarkCommentTag)}
      tags.each{|tag| tag.stub!(:name).and_return(SkipFaker.rand_char)}
      BookmarkCommentTag.should_receive(:find).and_return(tags)
      result = BookmarkComment.get_popular_tag_words
      result.size.should == 20
    end

    it "同じ名前のタグは表示されないこと" do
      tags = (1..5).map{|i| mock_model(BookmarkCommentTag)}
      tags.each{|tag| tag.stub!(:name).and_return("aaaa")}
      BookmarkCommentTag.should_receive(:find).and_return(tags)
      result = BookmarkComment.get_popular_tag_words
      result.size.should == 1
    end
  end

  # TODO .get_tagcloud_tags, .get_bookmark_tags, .get_tags
end
