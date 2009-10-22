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
      Tag.should_receive(:create_by_string)
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
  it { @board_entry.important?.should be_false }
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
# TODO: BoardEntry.find_visibleのテスト

describe "BoardEntry.get_category_words 複数のタグが見つかったとき" do
  before(:each) do
    @board_entry = mock_model(BoardEntry)
    @board_entry.stub!(:id).and_return(1)
    BoardEntry.should_receive(:find).and_return([@board_entry])
    @tag1 = mock_model(Tag)
    @tag2 = mock_model(Tag)
    @tag3 = mock_model(Tag)
    @tag1.stub!(:name).and_return('z')
    @tag2.stub!(:name).and_return('a')
    @tag3.stub!(:name).and_return('z')
    Tag.should_receive(:find).and_return([@tag1,@tag2,@tag3])
  end

  it "タグの名前をユニークにして並べ替えて返す" do
    BoardEntry.get_category_words.should == ['a','z']
  end
end

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

describe BoardEntry, '.get_symbol2name_hash' do
  describe 'あるグループのフォーラムが存在する場合' do
    before do
      @group = create_group(:gid => 'skip_group', :name => 'SKIPグループ')
      @user = create_user
      @entry = create_board_entry(:symbol => 'gid:skip_group', :user_id => @user.id)
    end
    it '対象記事を所有するグループのgidをキー、名前を値とするハッシュが取得できること' do
      BoardEntry.get_symbol2name_hash([@entry]).should == {'gid:skip_group' => 'SKIPグループ'}
    end
    describe '記事を所有するグループが論理削除された場合' do
      before do
        @group.logical_destroy
      end
      it '空ハッシュが取得できること' do
        BoardEntry.get_symbol2name_hash([@entry]).should == {}
      end
    end
  end
end

describe BoardEntry, '#prepare_send_mail' do
  before do
    @alice = create_user :user_options => {:name => 'アリス', :admin => true}, :user_uid_options => {:uid => 'alice'}
    @jack = create_user :user_options => {:name => 'ジャック', :admin => true}, :user_uid_options => {:uid => 'jack'}
    @nancy = create_user :user_options => {:name => 'ナンシー', :admin => true}, :user_uid_options => {:uid => 'nancy'}
    Mail.delete_all
  end
  describe '公開範囲が全体公開の場合' do
    before do
      @entry = create_board_entry(:symbol => @alice.symbol, :publication_type => 'public', :user_id => @alice.id)
    end
    it 'アクティブなユーザ全員分(自分以外)のMailが出来ていること' do
      lambda do
        @entry.prepare_send_mail
      end.should change(Mail, :count).by(User.active.count - 1)
    end
  end
  describe '公開範囲が直接指定の場合' do
    before do
      @entry = create_board_entry(:symbol => @alice.symbol, :publication_type => 'protected', :user_id => @alice.id, :publication_symbols_value => [@alice, @jack, @nancy].map(&:symbol).join(','))
    end
    it '直接指定された全員分(自分以外)のMailが出来ていること' do
      lambda do
        @entry.prepare_send_mail
      end.should change(Mail, :count).by(2)
    end
  end
  describe '公開範囲が自分だけのブログの場合' do
    before do
      @entry = create_board_entry(:symbol => 'uid:alice', :publication_type => 'private', :user_id => @alice.id)
    end
    it 'Mailが作られないこと' do
      lambda do
        @entry.prepare_send_mail
      end.should change(Mail, :count).by(0)
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
    end
    it '参加者全員分(自分以外)のMailが出来ていること' do
      lambda do
        @entry.prepare_send_mail
      end.should change(Mail, :count).by(2)
    end
    describe '記事を所有するグループが論理削除された場合' do
      before do
        @group.logical_destroy
      end
      it 'Mailに送信予定のレコードが作成されないこと' do
        lambda do
          @entry.prepare_send_mail
        end.should_not change(Mail, :count)
      end
    end
  end
end

describe BoardEntry, '#trackback_entries' do
  before do
    @entry = stub_model(BoardEntry)
    @trackback_entry = stub_model(BoardEntry, :tb_entry_id => @entry.id)
    @trackback_entry_ids = [@entry.id]
  end
  it '話題にしてくれた記事を取得する処理をコールすること' do
    user_id = SkipFaker.rand_num
    user_symbols = ['uid:hoge']
    @entry.should_receive(:entry_trackbacks).and_return([@trackback_entry])
    @entry.should_receive(:authorized_entries_except_given_user).with(user_id, user_symbols, @trackback_entry_ids)
    @entry.trackback_entries(user_id, user_symbols)
  end
end

describe BoardEntry, '#to_trackback_entries' do
  before do
    @entry = stub_model(BoardEntry)
    @to_trackback_entry = stub_model(BoardEntry, :board_entry_id => @entry.id)
    @to_trackback_entry_ids = [@entry.id]
  end
  it '話題にした記事一覧を取得する処理をコールすること' do
    user_id = SkipFaker.rand_num
    user_symbols = ['uid:hoge']
    @entry.should_receive(:to_entry_trackbacks).and_return([@to_trackback_entry])
    @entry.should_receive(:authorized_entries_except_given_user).with(user_id, user_symbols, @to_trackback_entry_ids)
    @entry.to_trackback_entries(user_id, user_symbols)
  end
end

describe BoardEntry, '#publication_users' do
  describe 'あるグループのフォーラムが存在する場合' do
    before do
      # あるグループの管理者がアリス, 参加者がマイク
      @alice = create_user :user_options => {:name => 'アリス', :admin => true}, :user_uid_options => {:uid => 'alice'}
      @mike = create_user :user_options => {:name => 'マイク', :admin => true}, :user_uid_options => {:uid => 'mike'}
      @group = create_group(:gid => 'skip_group', :name => 'SKIPグループ') do |g|
        g.group_participations.build(:user_id => @alice.id, :owned => true)
        g.group_participations.build(:user_id => @mike.id, :owned => false)
      end
      # アリスのブログで、そのグループ及びマイクが直接指定されている
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

describe BoardEntry, '#readable?' do
  before do
    @user = stub_model(User, :symbol => 'uid:notowner')
    @board_entry = stub_model(BoardEntry)
  end
  describe 'ログインユーザの記事の場合' do
    before do
      @user.should_receive(:symbol).and_return('uid:owner')
      @board_entry.should_receive(:symbol).and_return('uid:owner')
    end
    it 'trueが返ること' do
      @board_entry.readable?(@user).should be_true
    end
  end
  describe 'ログインユーザの記事ではない場合' do
    describe 'ログインユーザ所属グループの記事の場合' do
      before do
        @user.should_receive(:group_symbols).and_return(['gid:skip_dev'])
        @board_entry.should_receive(:symbol).at_least(:once).and_return('gid:skip_dev')
      end
      it 'trueが返ること' do
        @board_entry.readable?(@user).should be_true
      end
    end
    describe 'ログインユーザ所属グループの記事ではない場合' do
      before do
        @user.should_receive(:group_symbols).at_least(:once).and_return(['gid:skip_dev'])
        @board_entry.should_receive(:symbol).at_least(:once).and_return('uid:owner')
      end
      describe 'ログインユーザに公開されている記事の場合' do
        before do
          @board_entry.should_receive(:publicate?).and_return(true)
        end
        it 'trueが返ること' do
          @board_entry.readable?(@user).should be_true
        end
      end
      describe 'ログインユーザに公開されていない記事の場合' do
        before do
          @board_entry.should_receive(:publicate?).and_return(false)
        end
        it 'falseが返ること' do
          @board_entry.readable?(@user).should be_false
        end
      end
    end
  end
end

describe BoardEntry, '#point_incrementable?' do
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
        @board_entry.point_incrementable?(@user).should be_true
      end
    end
    describe '指定されたユーザが記事の作者の場合' do
      before do
        @board_entry.should_receive(:writer?).with(@user.id).and_return(true)
      end
      it 'falseが返却されること' do
        @board_entry.point_incrementable?(@user).should be_false
      end
    end
  end
  describe '指定されたユーザに記事の閲覧権限がない場合' do
    before do
      @board_entry.should_receive(:readable?).with(@user).and_return(false)
    end
    it 'falseが返却されること' do
      @board_entry.point_incrementable?(@user).should be_false
    end
  end
end

describe BoardEntry, '#authorized_entries_except_given_user' do
  before do
    # satoはsuzukiの記事の閲覧権限がない
    @sato = create_user(:user_options => {:name => 'Sato'}, :user_uid_options => {:uid => 'sato'})
    @sato_symbols = ["uid:#{@sato.uid}"]
    # yamadaはsuzukiの記事の閲覧権限がある
    @yamada = create_user(:user_options => {:name => 'Yamada'}, :user_uid_options => {:uid => 'yamada'})
    @yamada_symbols = ["uid:#{@yamada.uid}"]
    @yamada_entry = create_board_entry(:user_id => @yamada.id)
    @suzuki = create_user(:user_options => {:name => 'Suzuki'}, :user_uid_options => {:uid => 'suzuki'})
    @suzuki_entry = create_board_entry(:user_id => @suzuki.id, :publication_type => 'private')
    create_entry_publications(:board_entry_id => @suzuki_entry.id, :symbol => "uid:#{@suzuki.uid}")
    @entry_ids = [@yamada_entry.id, @suzuki_entry.id]
  end
  describe '[全公開の記事とSatoが閲覧できないprotectedな記事]からSatoが閲覧可能な記事を取得する場合' do
    it '一件の記事が取得できること' do
      @yamada_entry.send(:authorized_entries_except_given_user, @sato.id, @sato_symbols, @entry_ids).size.should == 1
    end
  end
  describe '[全公開の記事とYamadaが閲覧できるprotectedな記事]からYamadaが閲覧可能な記事を取得する場合' do
    it '二件の記事が取得できること' do
      @yamada_entry.send(:authorized_entries_except_given_user, @yamada.id, @yamada_symbols, @entry_ids).size.should == 2
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
