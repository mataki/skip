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

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe Admin::UserUid do
  describe "after_save" do
    before do
      create_items_expect_change
      @uid = Admin::UserUid.find_by_uid(@u.uid)
      @uid.uid = "fuga"
      @uid.save
    end

    it "同時に変更されること" do
      @b.reload
      @b.symbol.should == 'uid:fuga'
      @b.publication_symbols_value.should == 'uid:fuga'
      @b.contents.should be_include('uid:fuga')
      @b.entry_editors.first.symbol.should == 'uid:fuga'
      @b.entry_publications.first.symbol.should == 'uid:fuga'
      @message.reload
      @message.link_url.should == '/user/fuga'
      @sf.reload
      @sf.owner_symbol.should == 'uid:fuga'
      @mail.reload
      @mail.from_user_id.should == 'fuga'
      @mail.to_address_symbol.should == 'uid:fuga'
      @bookmark.reload
      @bookmark.url.should == '/user/fuga'
    end
  end
end

def create_items_expect_change
  @u = User.new({:name => 'hoge', :password => 'password', :password_confirmation => 'password'})
  @u.status = 'ACTIVE'
  @u.save!
  @u.user_uids.create({:uid => 'hoge'})
  @u.create_user_profile({:introduction => "uid:hoge"})
  @b = BoardEntry.create!({:title => "hoge", :contents => 'hoge', :date => Date.today, :entry_type => 'DIARY', :symbol => 'uid:hoge', :publication_symbols_value => 'uid:hoge', :contents => "geafdsaf uid:hoge fdsaf", :user_id => @u, :last_updated => Date.today})
  @b.entry_editors.create({:symbol => 'uid:hoge'})
  @b.entry_publications.create({:symbol => 'uid:hoge'})
  @message = Message.create!({:link_url => "/user/hoge", :user_id => @u})
  @sf = ShareFile.create!({:file_name => "hoge", :owner_symbol => 'uid:hoge', :publication_symbols_value => 'uid:hoge', :date => Date.today, :user_id => @u, :description => 'hoge'})
  @sf.share_file_publications.create({:symbol => 'uid:hoge'})
  @mail = Mail.create!({:from_user_id => 'hoge', :to_address_symbol => "uid:hoge", :user_entry_no => 1})
  @bookmark = Bookmark.create!({:url => '/user/hoge', :title => "hoge"})
  @ai = AntennaItem.create!({:value => 'uid:hoge', :antenna_id => 1})

  @u.user_uids.should_not be_empty
  @b.entry_editors.should_not be_empty
  @b.entry_publications.should_not be_empty
  @sf.share_file_publications.should_not be_empty
end
