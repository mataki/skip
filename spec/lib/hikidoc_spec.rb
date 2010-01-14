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

describe HikiDoc, :type => :helper do
  describe "parse_linkの [[str|link]] 変換" do
    describe "[[xss|javascript:alert(1);]]の場合" do
      it "リンクに変換されないこと" do
        text = "[[xss|javascript:alert(1);]]"
        convert(text).should_not have_tag("a")
      end
    end
    describe "[[xss|javascript:alert(1);http://]]の場合" do
      it "リンクに変換されないこと" do
        text = "[[xss|javascript:alert(1);http://]]"
        convert(text).should_not have_tag("a")
      end
    end
    describe "[[xss|http://example.com]]の場合" do
      it "リンクに変換されること" do
        text = "[[xss|http://example.com]]"
        convert(text).should have_tag("a[href=http://example.com]")
      end
    end
  end
  describe "URLの直書き変換" do
    describe "http:// が先頭からはじまっている場合" do
      it "リンクに変換されること" do
        text = "http://www.example.com/"
        convert(text).should have_tag("a[href=http://www.example.com/]")
      end
    end
    describe "http:// が途中からはじまっている場合" do
      it "リンクに変換されること" do
        text = "てすとてすと http://www.example.com/ てすと"
        convert(text).should have_tag("a[href=http://www.example.com/]")
      end
    end
  end
  def convert(text)
    HikiDoc.new(text,Regexp.new("http://www.example.com/")).to_html
  end
end
