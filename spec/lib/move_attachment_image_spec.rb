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

describe MoveAttachmentImage do
  before do
    @share_file_path = "#{RAILS_ROOT}/spec/tmp/share_file_path"
    @share_file_user_path = "#{@share_file_path}/user"
    @share_file_group_path = "#{@share_file_path}/group"
    SkipEmbedded::InitialSettings['share_file_path'] = @share_file_path
  end
  describe MoveAttachmentImage, '.user_share_file_path' do
    describe '共有ファイル保存ディレクトリが存在する場合' do
      before do
        FileUtils.mkdir_p @share_file_path
      end
      describe 'userディレクトリが存在する場合' do
        before do
          FileUtils.mkdir_p @share_file_user_path
        end
        it 'userディレクトリが返ること' do
          MoveAttachmentImage.user_share_file_path.should  == @share_file_user_path
        end
        after do
          FileUtils.rm_rf @share_file_user_path
        end
      end
      describe 'userディレクトリが存在しない場合' do
        it 'nilが返ること' do
          MoveAttachmentImage.user_share_file_path.should be_nil
        end
      end
    end
    describe '共有ファイル保存ディレクトリが存在しない場合' do
      it 'nilが返ること' do
        MoveAttachmentImage.user_share_file_path.should be_nil
      end
    end
  end

  describe MoveAttachmentImage, '.rename_uid_dir' do
    describe 'ユーザの共有ファイルパスが存在する場合' do
      before do
        FileUtils.mkdir_p @share_file_user_path
      end
      describe 'uidディレクトリが一件(uid:foo)存在する場合' do
        before do
          @uid_foo = 'foo'
          @user_id_foo = 99
          @share_file_foo_path = "#{@share_file_user_path}/#{@uid_foo}"
          FileUtils.mkdir_p @share_file_foo_path
        end
        describe 'uid:fooのUserが存在する場合' do
          before do
            @user_foo = stub_model(User, :uid => @uid_foo, :id => @user_id_foo)
            User.should_receive(:find_by_uid).and_return(@user_foo)
          end
          it 'uidディレクトリがidディレクトリにmoveされること' do
            MoveAttachmentImage.rename_uid_dir
            File.exist?(@share_file_foo_path).should be_false
            File.exist?("#{@share_file_user_path}/#{@user_id_foo}").should be_true
          end
          it '成功ログが出力されること' do
            MoveAttachmentImage.should_receive(:log_info)
            MoveAttachmentImage.rename_uid_dir
          end
        end
        describe 'uid:fooのUserが存在しない場合' do
          before do
            User.should_receive(:find_by_uid).and_return(nil)
          end
          it 'uidディレクトリがidディレクトリにmoveされないこと' do
            MoveAttachmentImage.rename_uid_dir
            File.exist?(@share_file_foo_path).should be_true
            File.exist?("#{@share_file_user_path}/#{@user_id_foo}").should be_false
          end
          it '失敗ログが出力されること' do
            MoveAttachmentImage.should_receive(:log_warn)
            MoveAttachmentImage.rename_uid_dir
          end
        end
        after do
          FileUtils.rm_rf @share_file_foo_path
        end
      end
      describe 'uidディレクトリが存在しない場合' do
        it '何もロギングされないこと' do
          MoveAttachmentImage.should_not_receive(:log_info)
          MoveAttachmentImage.should_not_receive(:log_warn)
          MoveAttachmentImage.rename_uid_dir
        end
      end
    end
    describe 'ユーザの共有ファイルパスが存在しない場合' do
      before do
        MoveAttachmentImage.should_receive(:user_share_file_path).and_return(nil)
      end
      it '何もロギングされないこと' do
        MoveAttachmentImage.should_not_receive(:log_info)
        MoveAttachmentImage.should_not_receive(:log_warn)
        MoveAttachmentImage.rename_uid_dir
      end
    end
  end

  describe MoveAttachmentImage, '.group_share_file_path' do
    describe '共有ファイル保存ディレクトリが存在する場合' do
      before do
        FileUtils.mkdir_p @share_file_path
      end
      describe 'groupディレクトリが存在する場合' do
        before do
          FileUtils.mkdir_p @share_file_group_path
        end
        it 'groupディレクトリが返ること' do
          MoveAttachmentImage.group_share_file_path.should == @share_file_group_path
        end
      end
      describe 'groupディレクトリが存在しない場合' do
        it 'nilが返ること' do
          MoveAttachmentImage.group_share_file_path.should be_nil
        end
      end
    end
    describe '共有ファイル保存ディレクトリが存在しない場合' do
      it 'nilが返ること' do
        MoveAttachmentImage.group_share_file_path.should be_nil
      end
    end
  end

  describe MoveAttachmentImage, '.rename_gid_dir' do
    describe 'グループの共有ファイルパスが存在する場合' do
      before do
        FileUtils.mkdir_p @share_file_group_path
      end
      describe 'gidディレクトリが一件(gid:bar)存在する場合' do
        before do
          @gid_bar = 'bar'
          @group_id_bar = 99
          @share_file_bar_path = "#{@share_file_group_path}/#{@gid_bar}"
          FileUtils.mkdir_p @share_file_bar_path
        end
        describe 'gid:barのGroupが存在する場合' do
          before do
            @group_bar = stub_model(Group, :gid => @gid_bar, :id => @group_id_bar)
            Group.should_receive(:find_by_gid).and_return(@group_bar)
          end
          it 'gidディレクトリがidディレクトリにmoveされること' do
            MoveAttachmentImage.rename_gid_dir
            File.exist?(@share_file_bar_path).should be_false
            File.exist?("#{@share_file_group_path}/#{@group_id_bar}").should be_true
          end
          it '成功ログが出力されること' do
            MoveAttachmentImage.should_receive(:log_info)
            MoveAttachmentImage.rename_gid_dir
          end
        end
        describe 'gid:barのGroupが存在しない場合' do
          before do
            Group.should_receive(:find_by_gid).and_return(nil)
          end
          it 'gidディレクトリがidディレクトリにmoveされないこと' do
            MoveAttachmentImage.rename_gid_dir
            File.exist?(@share_file_bar_path).should be_true
            File.exist?("#{@share_file_group_path}/#{@group_id_bar}").should be_false
          end
          it '失敗ログが出力されること' do
            MoveAttachmentImage.should_receive(:log_warn)
            MoveAttachmentImage.rename_gid_dir
          end
        end
      end
      describe 'gidディレクトリが存在しない場合' do
        before do
          MoveAttachmentImage.should_receive(:group_share_file_path).and_return(nil)
        end
        it '何もロギングされないこと' do
          MoveAttachmentImage.should_not_receive(:log_info)
          MoveAttachmentImage.should_not_receive(:log_warn)
          MoveAttachmentImage.rename_gid_dir
        end
      end
    end

    describe 'グループの共有ファイルパスが存在しない場合' do
      before do
        MoveAttachmentImage.should_receive(:group_share_file_path).and_return(nil)
      end
      it '何もロギングされないこと' do
        MoveAttachmentImage.should_not_receive(:log_info)
        MoveAttachmentImage.should_not_receive(:log_warn)
        MoveAttachmentImage.rename_gid_dir
      end
    end
  end

  describe MoveAttachmentImage, '.move_attachment_image' do
    before do
      @image_file_path = "#{RAILS_ROOT}/spec/tmp/image_file_path"
      FileUtils.mkdir_p @image_file_path
      SkipEmbedded::InitialSettings['image_file_path'] = @image_file_path
    end
    describe 'ベースとなるディレクトリが存在する場合' do
      before do
        @entry_image_base_path = "#{@image_file_path}/board_entries"
        MoveAttachmentImage.should_receive(:entry_image_base_path).and_return(@entry_image_base_path)
        FileUtils.mkdir_p @entry_image_base_path
      end
      describe 'user_idディレクトリが一件存在する場合' do
        before do
          @entry_user_id = 99
          @entry_image_user_path = "#{@entry_image_base_path}/#{@entry_user_id}"
          FileUtils.mkdir_p @entry_image_user_path
        end
        describe 'ファイルが一件存在する場合' do
          before do
            @file_name = 'file_name'
            @old_file_path = "#{@entry_image_user_path}/#{@file_name}"
            FileUtils.touch @old_file_path
            new_file_dir = "#{RAILS_ROOT}/spec/tmp/new_file_path"
            FileUtils.mkdir_p new_file_dir
            @new_file_path = "#{new_file_dir}/#{@file_name}"
            @share_file = ShareFile.new(
              :file_name => @file_name,
              :owner_symbol => 'uid:foo',
              :user_id => @entry_user_id,
              :content_type => 'application/octet-stream',
              :publication_type => 'public')
            @share_file.stub!(:full_path).and_return(@new_file_path)
            MoveAttachmentImage.should_receive(:new_share_file).and_return(@share_file)
          end
          it '共有ファイルが一件保存されること' do
            MoveAttachmentImage.move_attachment_image
            @share_file.new_record?.should be_false
          end
          it '共有ファイルの実体ファイルが保存されること' do
            MoveAttachmentImage.move_attachment_image
            File.exist?(@new_file_path).should be_true
          end
          it '元画像ファイルが削除されていること' do
            MoveAttachmentImage.move_attachment_image
            File.exist?(@old_file_path).should be_false
          end
        end
        describe 'ファイルが一件も存在しない場合' do
          it '共有ファイルが保存されないこと' do
            MoveAttachmentImage.should_not_receive(:new_share_file)
            MoveAttachmentImage.move_attachment_image
          end
        end
      end
      describe 'user_idディレクトリが存在しない場合' do
        it '共有ファイルが保存されないこと' do
          MoveAttachmentImage.should_not_receive(:new_share_file)
          MoveAttachmentImage.move_attachment_image
        end
      end
    end
    describe 'ベースとなるディレクトリが存在しない場合' do
      before do
        MoveAttachmentImage.should_receive(:entry_image_base_path).and_return(nil)
      end
      it '共有ファイルが作成されないこと' do
        MoveAttachmentImage.should_not_receive(:new_share_file)
        MoveAttachmentImage.move_attachment_image
      end
    end
    after do
      FileUtils.rm_rf @image_file_path
    end
  end

  describe MoveAttachmentImage, '.replace_entry_direct_link' do
    before do
      @replace_text = 'replace_text'
      contents = "foo#{@replace_text}"
      MoveAttachmentImage.stub!(:image_link_re).and_return(/#{@replace_text}/)
      @board_entry_foo = create_board_entry(:contents => contents, :category => 'skip,rails')
      @board_entry_bar = stub_model(BoardEntry, :symbol => 'uid:bar')
      BoardEntry.stub!(:find_by_id).and_return(@board_entry_bar)
    end
    describe '置換される場合(replaced_textの結果がnil以外)' do
      before do
        @replaced_text = 'replaced_text'
        MoveAttachmentImage.stub!(:replaced_text).and_return(@replaced_text)
      end
      it 'contentsが変換されること' do
#        lambda do
#          MoveAttachmentImage.replace_entry_direct_link @board_entry_foo
#        end.should change(@board_entry_foo, :contents).from("foo#{@replace_text}").to(replaced_contents)
        # 上記だとなぜか通らないので(#{column}_with_change!してるから?)以下のようにしておく。
        replaced_contents = "foo#{@replaced_text}"
        MoveAttachmentImage.replace_entry_direct_link @board_entry_foo
        @board_entry_foo.contents.should == replaced_contents
      end
      it 'categoryが変化しないこと' do
        lambda do
          MoveAttachmentImage.replace_entry_direct_link @board_entry_foo
        end.should_not change(@board_entry_foo, :category)
      end
      it 'updated_onが変化しないこと' do
        lambda do
          MoveAttachmentImage.replace_entry_direct_link @board_entry_foo
        end.should_not change(@board_entry_foo, :updated_on)
      end
    end
    describe '置換されない場合(replaced_textの結果がnil)' do
      before do
        MoveAttachmentImage.stub!(:replaced_text).and_return(nil)
      end
      it '保存されないこと' do
        @board_entry_foo.should_not_receive(:save!)
        MoveAttachmentImage.replace_entry_direct_link @board_entry_foo
      end
    end
  end

  describe MoveAttachmentImage, '.replace_entry_comment_direct_link' do
    before do
      @replace_text = 'replace_text'
      contents = "foo#{@replace_text}"
      MoveAttachmentImage.stub!(:image_link_re).and_return(/#{@replace_text}/)
      @board_entry = create_board_entry
      @board_entry_comment_foo = create_board_entry_comment(:contents => contents, :board_entry => @board_entry)
      @board_entry_bar = stub_model(BoardEntry, :symbol => 'uid:bar')
      BoardEntry.stub!(:find_by_id).and_return(@board_entry_bar)
    end
    describe '置換される場合(replaced_textの結果がnil以外' do
      before do
        @replaced_text = 'replaced_text'
        MoveAttachmentImage.stub!(:replaced_text).and_return(@replaced_text)
      end
      it 'contentsが変換されること' do
        replaced_contents = "foo#{@replaced_text}"
        MoveAttachmentImage.replace_entry_comment_direct_link @board_entry_comment_foo
        @board_entry_comment_foo.contents.should == replaced_contents
      end
      it 'updated_onが変化しないこと' do
        lambda do
          MoveAttachmentImage.replace_entry_comment_direct_link @board_entry_comment_foo
        end.should_not change(@board_entry_comment_foo, :contents)
      end
    end
    describe '置換されない場合(replaced_textの結果がnil' do
      before do
        MoveAttachmentImage.stub!(:replaced_text).and_return(nil)
      end
      it '保存されないこと' do
        @board_entry_comment_foo.should_not_receive(:save!)
        MoveAttachmentImage.replace_entry_comment_direct_link @board_entry_comment_foo
      end
    end
  end

  describe MoveAttachmentImage, '.new_share_file' do
    describe '移行対象の画像が添付された記事が存在する場合' do
      before do
        @board_entry = stub_model(BoardEntry, :symbol => 'symbol', :publication_type => 'publication_type', :publication_symbols_value => 'publication_symbols_value')
        MoveAttachmentImage.should_receive(:image_attached_entry).and_return(@board_entry)
        @share_file = MoveAttachmentImage.new_share_file(99, '99_image_file.png')
      end
      it '共有ファイルのインスタンスに必要な値が設定されること' do
        @share_file.file_name.should == 'image_file.png'
        @share_file.owner_symbol.should == 'symbol'
        @share_file.date.should_not be_nil
        @share_file.user_id.should == 99
        @share_file.content_type.should == 'image/png'
        @share_file.publication_type.should == 'publication_type'
        @share_file.publication_symbols_value == 'publication_symbols_value'
      end
    end
    describe '移行対象の画像が添付された記事が存在しない場合' do
      before do
        MoveAttachmentImage.should_receive(:image_attached_entry).and_return(nil)
      end
      it 'nilが返ること' do
        MoveAttachmentImage.new_share_file(99, '99_image_file.png').should be_nil
      end
    end
  end

  describe MoveAttachmentImage, '.content_type' do
    before do
      @share_file = stub_model(ShareFile)
    end
    describe '拡張子が指定されている場合' do
      describe '画像の拡張子(小文字)の場合' do
        before do
          @share_file.file_name = 'hoge.png'
        end
        it '結果がimage/pngとなること' do
          MoveAttachmentImage.content_type(@share_file).should == 'image/png'
        end
      end
      describe '画像の拡張子(大文字)の場合' do
        before do
          @share_file.file_name = 'hoge.PNG'
        end
        it '結果がimage/pngとなること' do
          MoveAttachmentImage.content_type(@share_file).should == 'image/png'
        end
      end
      describe '画像以外の拡張子の場合' do
        before do
          @share_file.file_name = 'hoge.txt'
        end
        it '結果がapplication/octet-streamとなること' do
          MoveAttachmentImage.content_type(@share_file).should == 'application/octet-stream'
        end
      end
    end
    describe '拡張子が指定されていない場合' do
      before do
        @share_file.file_name = 'hoge'
      end
      it '結果がapplication/octet-streamとなること' do
        MoveAttachmentImage.content_type(@share_file).should == 'application/octet-stream'
      end
    end
    describe 'ファイル名が[...]の場合' do
      before do
        @share_file.file_name = '...'
      end
      it '結果がapplication/octet-streamとなること' do
        MoveAttachmentImage.content_type(@share_file).should == 'application/octet-stream'
      end
    end
  end

  describe MoveAttachmentImage, '.share_file_name' do
    describe '対象の所有者に既に同名ファイルが登録されている場合' do
      before do
        ShareFile.should_receive(:find_by_owner_symbol_and_file_name).with('uid:owner', 'image_name.png').and_return(stub_model(ShareFile))
        ShareFile.should_receive(:find_by_owner_symbol_and_file_name).with('uid:owner', 'image_name_.png').and_return(nil)
      end
      it 'ファイル名末尾に_(アンダースコア)が付加されたファイル名が取得出来ること' do
        MoveAttachmentImage.share_file_name('uid:owner', '7_image_name.png').should == 'image_name_.png'
      end
    end
    describe '対象の所有者にまだ同名ファイルが登録されていない場合' do
      before do
        ShareFile.should_receive(:find_by_owner_symbol_and_file_name).with('uid:owner', 'image_name.png').and_return(nil)
      end
      it '共有ファイルに登録するファイル名が取得出来ること' do
        MoveAttachmentImage.share_file_name('uid:owner', '7_image_name.png').should == 'image_name.png'
      end
    end
  end

  describe MoveAttachmentImage, '.image_attached_entry' do
    it '画像の添付対象記事を取得しようとすること' do
      BoardEntry.should_receive(:find_by_id).with(7)
      MoveAttachmentImage.image_attached_entry('7_image_name.png')
    end
  end

  describe MoveAttachmentImage, '.measures_to_same_file' do
    describe 'ファイル名が同一の場合' do
      before do
        @share_file = stub_model(ShareFile, :file_name => 'skip.png')
        @image_file_name = '2_skip.png'
      end
      it 'nilが返ること' do
        MoveAttachmentImage.measures_to_same_file(@share_file, @image_file_name).should be_nil
      end
    end
    describe 'ファイル名が異なる場合' do
      before do
        @share_file = stub_model(ShareFile, :file_name => 'skip_.png')
        @image_file_name = '2_skip.png'
      end
      describe '移行対象画像が添付された記事が存在する場合' do
        before do
          @board_entry = create_board_entry(:contents => 'skip.png\nskip.png', :category => 'skip,rails')
          MoveAttachmentImage.should_receive(:image_attached_entry).and_return(@board_entry)
        end
        it '対象ファイルの属する記事の本文内のファイル名が置換されること' do
#          lambda do
#            MoveAttachmentImage.measures_to_same_file(@share_file, @image_file_name)
#          end.should change(@board_entry, :contents).to('skip_.png\nskip_.png')
          # 上記だとなぜか通らないので(#{column}_with_change!してるから?)以下のようにしておく。
          replaced_contents = "skip_.png\\nskip_.png"
          MoveAttachmentImage.measures_to_same_file(@share_file, @image_file_name)
          @board_entry.contents.should == replaced_contents
        end
        it 'trueが返ること' do
          MoveAttachmentImage.measures_to_same_file(@share_file, @image_file_name).should be_true
        end
      end
      describe '対象ファイルの属する記事が存在するが、所有するグループ/ユーザが存在しない場合' do
        before do
          @board_entry = create_board_entry(:contents => 'skip.png\nskip.png', :category => 'skip,rails')
          @board_entry.should_receive(:save).and_return(false)
          MoveAttachmentImage.should_receive(:image_attached_entry).and_return(@board_entry)
        end
        it 'エラーログが表示されること' do
          MoveAttachmentImage.should_receive(:log_warn)
          MoveAttachmentImage.measures_to_same_file(@share_file, @image_file_name)
        end
        it 'nilが返ること' do
          MoveAttachmentImage.measures_to_same_file(@share_file, @image_file_name).should be_nil
        end
      end
      describe '移行対象画像が添付された記事が存在しない場合' do
        before do
          MoveAttachmentImage.should_receive(:image_attached_entry).and_return(nil)
        end
        it 'nilが返ること' do
          MoveAttachmentImage.measures_to_same_file(@share_file, @image_file_name).should be_nil
        end
      end
    end
  end

  after do
    FileUtils.rm_rf "#{RAILS_ROOT}/spec/tmp/"
  end
  after(:all) do
    # TODO move_attachment_image自体で元に戻しておくべき
    BoardEntry.record_timestamps = true
    BoardEntryComment.record_timestamps = true
  end
end

