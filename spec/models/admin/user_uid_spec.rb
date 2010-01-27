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

describe Admin::UserUid, "#after_update" do
  before do
    @user = create_user
    @user.stub!(:delete_auth_tokens!)
    @before_uid = SkipFaker.rand_char
    @uid = Admin::UserUid.create!(:uid => @before_uid, :uid_type => UserUid::UID_TYPE[:username], :user_id => @user.id)
    @uid.stub!(:user).and_return(@user)
  end
  describe "新しいIDで更新の場合" do
    before do
      @uid.uid = @new_uid = SkipFaker.rand_char
    end
    it "renameが呼ばれること" do
      Admin::UserUid.should_receive(:rename).with(@before_uid, @new_uid)
      @uid.save!
    end
    it "強制ログアウトされること" do
      @user.should_receive(:delete_auth_tokens!)
      @uid.save!
    end
    it 'Userの更新日が更新されること' do
      lambda do
        @uid.save!
      end.should change(@user, :updated_on)
    end
  end
  describe "同じIDで更新する場合" do
    before do
      @uid.stub!(:uid_changed?).and_return(false)
    end
    it "renameが呼ばれないこと" do
      Admin::UserUid.should_not_receive(:rename)
      @uid.save!
    end
    it 'Userの更新日が更新されないこと' do
      lambda do
        @uid.save!
      end.should_not change(@user, :attributes)
    end
  end
end

describe Admin::UserUid, "#after_create" do
  describe "既にmasterのuidが存在している場合" do
    before do
      @user = create_user :user_uid_options => {}
      @master_uid = @user.code
    end
    describe "usernameが存在していない場合" do
      it "self.renameが呼ばれること" do
        new_uid = "username"
        Admin::UserUid.should_receive(:rename).with(@master_uid, new_uid)
        Admin::UserUid.create!(:uid => new_uid, :uid_type => UserUid::UID_TYPE[:username], :user_id => @user.id)
      end
      it 'Userの更新日が更新されること' do
        lambda do
          Admin::UserUid.create!(:uid => 'username', :uid_type => UserUid::UID_TYPE[:username], :user_id => @user.id)
          @user.reload
        end.should change(@user, :updated_on)
      end
    end
    describe "usernameが存在している場合" do
      before do
        created_uid = 'createduid'
        created = Admin::UserUid.create!(:uid => created_uid, :uid_type => UserUid::UID_TYPE[:username], :user_id => @user.id)
      end
      it "self.renameが呼ばれないこと" do
        new_uid = "username"
        Admin::UserUid.should_not_receive(:rename)
        Admin::UserUid.create!(:uid => new_uid, :uid_type => UserUid::UID_TYPE[:username], :user_id => @user.id)
      end
      it 'Userが更新されないこと' do
        lambda do
          Admin::UserUid.create!(:uid => 'username', :uid_type => UserUid::UID_TYPE[:username], :user_id => @user.id)
          @user.reload
        end.should_not change(@user.updated_on, :to_s)
      end
    end
  end
  describe "masterが存在していない場合" do
    it "self.renameが呼ばれないこと" do
      new_uid = "username"
      Admin::UserUid.should_not_receive(:rename)
      Admin::UserUid.create!(:uid => new_uid, :uid_type => UserUid::UID_TYPE[:username], :user_id => 2)
    end
  end
end

describe Admin::UserUid, "#rename" do
  before do
    create_items_expect_change
    @owner_symbol_was = @sf.owner_symbol
    @uid = Admin::UserUid.find_by_uid(@u.uid)
    @new_uid = SkipFaker.rand_char
    @new_symbol = "uid:#{@new_uid}"
    Admin::UserUid.rename(@uid.uid, @new_uid)
  end

  it "同時に変更されること" do
    @b.reload
    @b.symbol.should == @new_symbol
    @b.publication_symbols_value.should == @new_symbol
    @b.contents.should be_include(@new_symbol)
    @b.entry_editors.first.symbol.should == @new_symbol
    @b.entry_publications.first.symbol.should == @new_symbol
    @sf.reload
    @sf.owner_symbol.should == @new_symbol
  end

  def create_items_expect_change
    uid_str = SkipFaker.rand_char
    @u = User.new({:name => uid_str, :password => 'Password1', :password_confirmation => 'Password1', :email => SkipFaker.email})
    @u.status = 'ACTIVE'
    @u.save!
    @u.user_uids.create!({:uid => uid_str})
    @b = BoardEntry.create!({:title => uid_str, :contents => uid_str, :date => Date.today, :entry_type => 'DIARY', :symbol => "uid:#{uid_str}", :publication_symbols_value => "uid:#{uid_str}", :contents => "geafdsaf uid:#{uid_str} fdsaf", :user_id => @u, :last_updated => Date.today})
    @b.entry_editors.create!({:symbol => "uid:#{uid_str}"})
    @b.entry_publications.create!({:symbol => "uid:#{uid_str}"})
    file = mock_uploaed_file
    @sf = ShareFile.new({:file => file, :file_name => uid_str, :owner_symbol => "uid:#{uid_str}", :publication_symbols_value => "uid:#{uid_str}", :date => Date.today, :user_id => @u, :description => uid_str})
    @sf.accessed_user = @u
    @sf.save!
    @sf.share_file_publications.create!({:symbol => "uid:#{uid_str}"})

    @u.user_uids.should_not be_empty
    @b.entry_editors.should_not be_empty
    @b.entry_publications.should_not be_empty
    @sf.share_file_publications.should_not be_empty
    FileUtils.mkdir_p(ShareFile.dir_path(@sf.owner_symbol))
  end
end
