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

describe OpenidIdentifier do
  before(:each) do
    @openid_identifier = OpenidIdentifier.new({ :url => "http://hoge.example.com", :user_id => 1})
  end

  it "should be valid" do
    @openid_identifier.should be_valid
  end
end

describe OpenidIdentifier, 'validation' do
  before do
    @openid_identifier = OpenidIdentifier.new
  end
  it 'urlがユニークであること' do
    create_openid_identifier(:url => 'http://skip.openid.com/')
    @openid_identifier.url = 'http://skip.openid.com/'
    @openid_identifier.valid?.should be_false
    # 大文字小文字が異なる場合もNG
    @openid_identifier.url = 'http://Skip.openid.com/'
    @openid_identifier.valid?.should be_false
  end
end

describe OpenidIdentifier, '#url' do
  before do
    @openid_identifier = OpenidIdentifier.new({ :url => "http://hoge.example.com/", :user_id => 1})
  end

  describe '不正な URL を指定した場合' do
    before do
      @openid_identifier.url = '::::::'
    end

    it { @openid_identifier.should_not be_valid }
    it { @openid_identifier.should have(1).errors_on(:url) }
  end

  describe '正規化されていない URL を指定した場合' do
    before do
      @openid_identifier.url = 'example.com'
    end

    it '保存時に正規化されること' do
      proc {
        @openid_identifier.save
      }.should change(@openid_identifier, :url).from('example.com').to('http://example.com/')
    end
  end

  describe 'update_attribute でも' do
    it '正規化されること' do
      proc {
        @openid_identifier.update_attribute(:url, 'example.com')
      }.should change(@openid_identifier, :url).from(nil).to('http://example.com/')
    end
  end
end

def create_openid_identifier(options = {})
  openid_identifier = OpenidIdentifier.new({:url => 'http://skip.example.com/', :user_id => 1}.merge(options))
  openid_identifier.save!
  openid_identifier
end
