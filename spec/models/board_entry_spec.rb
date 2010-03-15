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

describe BoardEntry, "に何も値が設定されていない場合" do
  before(:each) do
    @board_entry = BoardEntry.new
  end
  it { @board_entry.should_not be_valid }
  it { @board_entry.should have(1).errors_on(:title) }
  it { @board_entry.should have(1).errors_on(:contents) }
  it { @board_entry.should have(1).errors_on(:date) }
  it { @board_entry.should have(1).errors_on(:user_id) }
end

describe BoardEntry, "に正しい値が設定されている場合" do
  before(:each) do
    @board_entry = BoardEntry.new({ :title => "hoge", :contents => "hoge",
                                    :date => Date.today, :user_id => 1,
    # FIXME この行からvalidateがかかっていないのに保存しようとするとMysqlエラー
                                    :last_updated => Date.today })
  end

  it { @board_entry.should be_valid }
  it "正しく保存される" do
    lambda { @board_entry.save! }.should_not raise_error
  end
  it "保存するときにBoardEntryPointが作成される" do
    BoardEntryPoint.should_receive(:create)
    @board_entry.save!
  end

  describe BoardEntry, "にタグが設定されている場合" do
    before(:each) do
      @board_entry.category = 'foo,bar'
    end

    it "保存する際にTagが保存される" do
      Tag.should_receive(:create_by_comma_tags)
      @board_entry.save
    end
  end
end

describe BoardEntry, "があるユーザのブログだったとき" do
  fixtures :board_entries
  before(:each) do
    @board_entry = board_entries(:a_entry)
  end

  it { @board_entry.permalink.should == "/page/#{@board_entry.id}" }
  it { @board_entry.public?.should be_true}
  it { @board_entry.private?.should be_false }
  it { @board_entry.protected?.should be_false  }
  # TODO: このメソッドはいらない気がする。過去の消し忘れか
  #  it { @board_entry.owner_is_public?.should be_true }
  # TODO: BoardEntry#get_around_entryのテスト
  #      select文の + の意味が分からん
  #      文字列連結をしているようだ
  #      周りの記事を探すだけなのになぜここまでの処理が必要か？
end

# TODO: BoardEntry.make_conditionsのテスト

describe "BoardEntry.get_popular_tag_words で複数タグが見つかったとき" do
  before(:each) do
    @tag1 = mock_model(EntryTag)
    @tag1.stub!(:name).and_return('z')
    @tag2 = mock_model(EntryTag)
    @tag2.stub!(:name).and_return('a')
    @tag3 = mock_model(EntryTag)
    @tag3.stub!(:name).and_return('z')
    EntryTag.should_receive(:find).and_return([@tag1,@tag2,@tag3])
  end
  it "タグの名前をユニークして返す" do
    BoardEntry.get_popular_tag_words.should == ['z','a']
  end
end

describe BoardEntry, '#after_save' do
  describe 'タグの作成' do
    describe 'タグが入力されていない場合' do
      before do
        @entry = create_board_entry :category => ''
        @entry.save
      end
      it { @entry.entry_tags.size.should == 0 }
    end
    describe 'タグが入力されている場合' do
      before do
        @entry = create_board_entry :category => SkipFaker.comma_tags(:qt => 2)
        @entry.save
      end
      it { @entry.entry_tags.size.should == 2 }
    end
  end
end

describe BoardEntry, '.unescape_href' do
  it "hrefの部分のみがアンエスケープされること" do
    text = <<-EOF
<a href=\"http://maps.google.co.jp/maps?f=q&amp;source=s_q&amp;hl=ja&amp;geocode=&amp;q=%E6%9D%B1%E4%BA%AC%E3%82%BF%E3%83%AF%E3%83%BC&amp;vps=1&amp;jsv=160f&amp;sll=36.5626,136.362305&amp;sspn=46.580215,79.101563&amp;ie=UTF8&amp;latlng=35658632,139745411,12292286392395809068&amp;ei=uX0fSoLaEIyyuwP5r8HtAw&amp;sig2=afRsS3vW83gTeW9KYfv0jg&amp;cd=1\">&amp;hoho</a>
EOF
    @result = BoardEntry.unescape_href(text)
    @result.should == <<-EOF
<a href="http://maps.google.co.jp/maps?f=q&source=s_q&hl=ja&geocode=&q=%E6%9D%B1%E4%BA%AC%E3%82%BF%E3%83%AF%E3%83%BC&vps=1&jsv=160f&sll=36.5626,136.362305&sspn=46.580215,79.101563&ie=UTF8&latlng=35658632,139745411,12292286392395809068&ei=uX0fSoLaEIyyuwP5r8HtAw&sig2=afRsS3vW83gTeW9KYfv0jg&cd=1">&amp;hoho</a>
EOF
  end

  it "2つaタグがある場合でもただしく動作すること" do
    text = "hoge<a href='/hoge?f=q&amp;hl=h1' id='ff'>aa\na</a>aa&amp;aa<a href=\"/fuga?f=q&amp;h=h\">bb&amp;b</a>"
    BoardEntry.unescape_href(text).should ==
      "hoge<a href='/hoge?f=q&hl=h1' id='ff'>aa\na</a>aa&amp;aa<a href=\"/fuga?f=q&h=h\">bb&amp;b</a>"
  end

  it '置換対象外の場合は引数がそのまま返ること' do
    BoardEntry.unescape_href('<p>foo</p>').should == '<p>foo</p>'
  end
end

describe BoardEntry, '#send_contact_mails' do
  describe 'メールを送信しない場合' do
    before do
      @entry = create_board_entry
      @entry.send_mail = '0'
    end
    it 'Emailが作られないこと' do
      lambda do
        @entry.send_contact_mails
      end.should change(Email, :count).by(0)
    end
  end
  describe 'メールを送信する場合' do
    before do
      @alice = create_user :user_options => {:name => 'アリス', :admin => true}
      @jack = create_user :user_options => {:name => 'ジャック', :admin => true}
      @nancy = create_user :user_options => {:name => 'ナンシー', :admin => true}
    end
    describe '公開範囲が全体公開の場合' do
      before do
        @entry = create_board_entry(:symbol => @alice.symbol, :publication_type => 'public', :user_id => @alice.id)
        @entry.send_mail = '1'
      end
      describe '全体へのメール送信が有効の場合' do
        before do
          SkipEmbedded::InitialSettings['mail']['enable_send_email_to_all_users'] = true
        end
        it 'アクティブなユーザ全員分(自分以外)のEmailが出来ていること' do
          lambda do
            @entry.send_contact_mails
          end.should change(Email, :count).by(User.active.count - 1)
        end
      end
      describe '全体へのメール送信が無効の場合' do
        before do
          SkipEmbedded::InitialSettings['mail']['enable_send_email_to_all_users'] = false
        end
        it 'Emailが作られないこと' do
          lambda do
            @entry.send_contact_mails
          end.should change(Email, :count).by(0)
        end
      end
    end
    describe '公開範囲が直接指定の場合' do
      before do
        @entry = create_board_entry(:symbol => @alice.symbol, :publication_type => 'protected', :user_id => @alice.id, :publication_symbols_value => [@alice, @jack, @nancy].map(&:symbol).join(','))
        @entry.send_mail = '1'
      end
      it '直接指定された全員分(自分以外)のEmailが出来ていること' do
        lambda do
          @entry.send_contact_mails
        end.should change(Email, :count).by(2)
      end
    end
    describe '公開範囲が自分だけのブログの場合' do
      before do
        @entry = create_board_entry(:symbol => 'uid:alice', :publication_type => 'private', :user_id => @alice.id)
        @entry.send_mail = '1'
      end
      it 'Emailが作られないこと' do
        lambda do
          @entry.send_contact_mails
        end.should change(Email, :count).by(0)
      end
    end
    describe '公開範囲が参加者のみのフォーラムの場合' do
      before do
        @group = create_group(:gid => 'skip_group', :name => 'SKIPグループ') do |g|
          g.group_participations.build(:user_id => @alice.id, :owned => true)
          g.group_participations.build(:user_id => @jack.id)
          g.group_participations.build(:user_id => @nancy.id)
        end
        @entry = create_board_entry(:symbol => @group.symbol, :publication_type => 'private', :user_id => @alice.id, :publication_symbols_value => @group.symbol)
        @entry.send_mail = '1'
      end
      it '参加者全員分(自分以外)のEmailが出来ていること' do
        lambda do
          @entry.send_contact_mails
        end.should change(Email, :count).by(2)
      end
      describe '記事を所有するグループが論理削除された場合' do
        before do
          @group.logical_destroy
        end
        it 'Emailに送信予定のレコードが作成されないこと' do
          lambda do
            @entry.send_contact_mails
          end.should_not change(Email, :count)
        end
      end
    end
  end
end

describe BoardEntry, '#send_trackbacks!' do
  before do
    @sato = create_user(:user_options => {:name => 'Sato'})
    @board_entry = create_board_entry
    @trackback_entry_1 = create_board_entry
    @trackback_entry_2 = create_board_entry
  end
  describe '2つの記事のidを話題の記事として指定する場合' do
    it '2件のentry_trackbacksが作成されること' do
      lambda do
        @board_entry.send_trackbacks!(@sato, [@trackback_entry_1, @trackback_entry_2].map(&:id).join(','))
      end.should change(EntryTrackback, :count).by(2)
    end
  end
  describe '2件のentry_trackbacksが作成済みの場合' do
    before do
      @board_entry.to_entry_trackbacks.create(:board_entry_id => @trackback_entry_1.id)
      @board_entry.to_entry_trackbacks.create(:board_entry_id => @trackback_entry_2.id)
    end
    describe '1つの記事のidを話題の記事として指定する場合' do
      it '1件のentry_trackbacksが削除されること' do
        lambda do
          @board_entry.send_trackbacks!(@sato, @trackback_entry_1.id.to_s)
        end.should change(EntryTrackback, :count).by(-1)
      end
    end
  end
end

describe BoardEntry, '#publication_users' do
  describe 'あるグループのフォーラムが存在する場合' do
    before do
      # あるグループの管理者がアリス, 参加者がマイク, デイブ(退職者)
      @alice = create_user :user_options => {:name => 'アリス', :admin => true}
      @mike = create_user :user_options => {:name => 'マイク', :admin => true}
      @dave = create_user :user_options => {:name => 'デイブ', :admin => true}, :status => 'RETIRED'
      @group = create_group(:gid => 'skip_group', :name => 'SKIPグループ') do |g|
        g.group_participations.build(:user_id => @alice.id, :owned => true)
        g.group_participations.build(:user_id => @mike.id, :owned => false)
        g.group_participations.build(:user_id => @dave.id, :owned => false)
      end
    end
    describe "アリスのブログで、そのグループ及びマイクが直接指定されている" do
      before do
        @entry = create_board_entry(:symbol => 'uid:alice', :publication_type => 'protected', :user_id => @alice.id, :publication_symbols_value => [@group, @mike].map(&:symbol).join(','))
      end
      it '公開されているユーザの配列が返ること' do
        @entry.publication_users.should == [@alice, @mike]
      end
      describe '記事を所有するグループが論理削除された場合' do
        before do
          @group.logical_destroy
        end
        it '公開されているユーザの配列が返ること' do
          @entry.publication_users.should == [@mike]
        end
      end
    end

    it "アリスのブログをprivateにしている場合、公開されているユーザの配列が返ること" do
      @entry = create_board_entry(:symbol => 'uid:alice', :publication_type => 'private', :user_id => @alice.id, :publication_symbols_value => "")
      @entry.publication_users.should == [@alice]
    end

    it "アリスのブログをpublicにしている場合、アクティブな全ユーザの配列が返ること" do
      @entry = create_board_entry(:symbol => 'uid:alice', :publication_type => 'public', :user_id => @alice.id, :publication_symbols_value => "")
      @entry.publication_users.size.should == User.active.all.size
    end

    it 'SKIPグループの直接指定されている記事の場合、公開されているユーザの配列が返ること' do
      @entry = create_board_entry(:symbol => 'gid:skip_group', :publication_type => 'protected', :user_id => @alice.id, :publication_symbols_value => [@group, @mike].map(&:symbol).join(','))
      @entry.publication_users.should == [@alice, @mike]
    end

    it 'SKIPグループに private で公開されている記事の場合、公開されているユーザの配列が返ること' do
      @entry = create_board_entry(:symbol => 'gid:skip_group', :publication_type => 'private', :user_id => @alice.id, :publication_symbols_value => "")
      @entry.publication_users.should == [@alice, @mike]
    end

    it "SKIPグループで public に公開されている記事の場合、アクティブな全ユーザの配列a返ること" do
      @entry = create_board_entry(:symbol => 'gid:skip_group', :publication_type => 'public', :user_id => @alice.id, :publication_symbols_value => "")
      @entry.publication_users.size.should == User.active.all.size
    end
  end
end

describe BoardEntry, '.owner' do
  describe '書き込み場所がUserの場合(symbolがuid:xxxxxx)' do
    before do
      @symbol = 'uid:111111'
      @user = mock_model(User)
      User.should_receive(:find_by_uid).and_return(@user)
    end
    it '書きこみ場所(所有者)としてユーザが返却されること' do
      BoardEntry.owner(@symbol).should == @user
    end
  end
  describe '書き込み場所がGroupの場合(symbolがgid:xxxxxx)' do
    before do
      @group = create_group :gid => 'skip_group'
    end
    it '書き込み場所(所有者)としてグループが返却されること' do
      BoardEntry.owner('gid:skip_group').should == @group
    end
    describe '書き込み場所のグループが論理削除された場合' do
      before do
        @group.logical_destroy
      end
      it 'nilが返ること' do
        BoardEntry.owner('gid:skip_group').should be_nil
      end
    end
  end
  describe '書き込み場所が不明な場合' do
    before do
      @symbol = 'hoge:111111'
    end
    it 'nilが返却されること' do
      BoardEntry.owner(@symbol).should be_nil
    end
  end
end

describe BoardEntry, '#load_owner' do
end

describe BoardEntry, '#accessible_without_writer?' do
  before do
    @board_entry = stub_model(BoardEntry)
    @user = stub_model(User)
  end
  describe '指定されたユーザに記事の閲覧権限がある場合' do
    before do
      @board_entry.should_receive(:readable?).with(@user).and_return(true)
    end
    describe '指定されたユーザが記事の作者ではない場合' do
      before do
        @board_entry.should_receive(:writer?).with(@user.id).and_return(false)
      end
      it 'trueが返却されること' do
        @board_entry.accessible_without_writer?(@user).should be_true
      end
    end
    describe '指定されたユーザが記事の作者の場合' do
      before do
        @board_entry.should_receive(:writer?).with(@user.id).and_return(true)
      end
      it 'falseが返却されること' do
        @board_entry.accessible_without_writer?(@user).should be_false
      end
    end
  end
  describe '指定されたユーザに記事の閲覧権限がない場合' do
    before do
      @board_entry.should_receive(:readable?).with(@user).and_return(false)
    end
    it 'falseが返却されること' do
      @board_entry.accessible_without_writer?(@user).should be_false
    end
  end
end

describe BoardEntry, ".aim_type" do
  before do
    BoardEntry.delete_all
    params = { :title => "hoge", :contents => "hoge", :date => Date.today, :user_id => 1, :last_updated => Date.today }
    @entries = BoardEntry::AIM_TYPES.map do |type|
      BoardEntry.create!(params.merge(:aim_type => type))
    end.index_by(&:aim_type)
  end
  it "1つで検索できること" do
    result = BoardEntry.aim_type('entry').all
    result.size.should == 1
    result.should be_include(@entries['entry'])
  end
  it "2つの条件で検索できること" do
    result = BoardEntry.aim_type('entry,question')
    result.size.should == 2
    result.should be_include(@entries['entry'])
    result.should be_include(@entries['question'])
  end
end

describe BoardEntry, '#be_close!' do
  subject do
    creater = create_user(:user_options => {:name => 'Sato'}, :user_uid_options => {:uid => 'sato'})
    @board_entry = create_board_entry(:publication_type => 'protected', :entry_type => @entry_type, :symbol => @owner_symbol, :user_id => creater.id)
    @board_entry.entry_publications.create!(:symbol => 'uid:symbol')
    @board_entry.entry_editors.create!(:symbol => 'uid:symbol')
    @board_entry.be_close!
    @board_entry.reload
    @board_entry
  end

  describe 'ブログの場合' do
    before do
      @entry_type = 'DIARY'
      @owner_symbol = 'uid:sato'
    end
    it '公開範囲がprivateになること' do
      subject.publication_type.should == 'private'
    end

    it '関連するentry_publicationsが削除されること' do
      subject.entry_publications.should be_empty
    end

    it '関連するentry_editorsが削除されること' do
      subject.entry_editors.should be_empty
    end
  end

  describe 'フォーラムの場合' do
    before do
      @entry_type = 'GROUP_BBS'
      group = create_group(:gid => 'skip_group', :name => 'SKIPグループ')
      @owner_symbol = 'gid:skip_group'
    end
    it '公開範囲が変化しないこと' do
      subject.publication_type.should == 'protected'
    end

    it '関連するentry_publicationsが削除されないこと' do
      subject.entry_publications.should_not be_empty
    end

    it '関連するentry_editorsが削除されないこと' do
      subject.entry_editors.should_not be_empty
    end
  end
end
