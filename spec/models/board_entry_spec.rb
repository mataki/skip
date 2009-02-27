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

describe BoardEntry do
  fixtures :board_entries, :groups, :users, :mails, :tags, :user_uids

  def test_validate_category
    # カテゴリに+,/,-,_,.以外の記号を含む場合 => validationにひっかかる
    # その他タグ周りの細かいvalidateについてはTagのテストで実施している
    @a_entry.category = "[あ=あ][*いえ]"
    assert !@a_entry.valid?
  end

  def test_after_save
    @a_entry.category = ''
    @a_entry.save
    assert_equal @a_entry.entry_tags.size, 0

    @a_entry.category = SkipFaker.comma_tags :qt => 2
    @a_entry.save
    assert_equal @a_entry.entry_tags.size, 2
  end

# FIXME テストを汎用化する
  def test_publication_users
    entry = BoardEntry.new(store_entry_params({ :user_id => @a_user.id,
                                                :last_updated => Time.now,
                                                :symbol => "uid:#{@a_user.uid}"}))

    # 単一ユーザに対する公開
    entry.entry_publications.build(:symbol => "uid:#{@a_group_owned_user.uid}")
    users = entry.publication_users.map{ |user| user.id }
    assert_equal 1, users.size
    assert_equal @a_group_owned_user.id, users.first

    # 複数ユーザに対する公開
    entry.entry_publications.build(:symbol => "uid:#{@a_group_joined_user.uid}")
    users = entry.publication_users.map{ |user| user.id }
    assert_equal 2, users.size
    assert users.include?(@a_group_owned_user.id)
    assert users.include?(@a_group_joined_user.id)
  end

  def test_prepare_send_mail
    # 直接指定の記事
    entry = BoardEntry.new(store_entry_params({ :user_id => @a_user.id,
                                                :last_updated => Time.now,
                                                :symbol => "uid:#{@a_user.uid}",
                                                :category => "[#{Tag::NOTICE_TAG}]",
                                                :publication_type => 'private'}))

    Mail.delete_all
    # 単一ユーザに対する連絡
    entry.entry_publications.build(:symbol => "uid:#{@a_group_owned_user.uid}")
    entry.prepare_send_mail
    mails = Mail.find(:all)
    assert_equal 1, mails.size
    assert_equal @a_group_owned_user.email, mails.first.to_address

    Mail.delete_all
    # 複数ユーザに対する連絡
    entry.entry_publications.build(:symbol => "uid:#{@a_group_joined_user.uid}")
    entry.prepare_send_mail
    mails, mail_address = get_mails

    assert_equal 2, mails.size
    assert_not_nil mail_address.index(@a_group_owned_user.email)
    assert_not_nil mail_address.index(@a_group_joined_user.email)
    Mail.delete_all
  end

private

  def get_mails
    mails = Mail.find(:all)
    mail_address = ""
    mails.each { |mail| mail_address += mail.to_address + "," }
    return mails, mail_address
  end

  def store_entry_params params={}
    entry_template = {
      :title => "test",
      :contents => "test",
      :date => Date.today,
      :category => "",
      :entry_type => "BBS",
      :ignore_times => false,
      :user_entry_no => 1,
      :editor_mode => "hiki",
      :lock_version => 0,
      :publication_type => "public",
      :entry_trackbacks_count => 0,
      :board_entry_comments_count => 0
    } # user_id, last_updated, symbolが未設定

    params.each do |key, value|
      entry_template.store(key, value)
    end
    return entry_template
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
      @symbol = 'gid:111111'
      @group = mock_model(Group)
      Group.should_receive(:find_by_gid).and_return(@group)
    end
    it '書き込み場所(所有者)としてグループが返却されること' do
      BoardEntry.owner(@symbol).should == @group
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
