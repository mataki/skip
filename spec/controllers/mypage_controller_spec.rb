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

describe MypageController do
  before(:each) do
    @user = user_login
    ActionMailer::Base.deliveries.clear
  end

  describe "POST /mypage/apply_email" do
    before do
      session[:user_id] = 1
    end
    it "should be successful" do
      post :apply_email, {:applied_email => {:email => SkipFaker.email}}
      response.should be_success
      assigns[:menu].should == "manage_email"
      assigns[:user].should == @user
      AppliedEmail.find_by_id(assigns(:applied_email).id).should_not be_nil
      ActionMailer::Base.deliveries.first.body.should match(/http:\/\/test\.host\/mypage\/update_email\/.*/m)
    end
  end

  describe "POST /mypage/apply_ident_url" do
    before do
      INITIAL_SETTINGS['login_mode'] = 'rp'
      INITIAL_SETTINGS['fixed_op_url'] = nil
    end
    describe '新規登録の場合' do
      before do
        @url = 'http://example.com'

        @user = user_login

        @openid_identifier = stub_model(OpenidIdentifier, :user_id => @user.id, :url => @url)
        @openid_identifier.stub!(:url=).with(@url)

        @openid_identifiers = mock('openid_identifiers')
        @openid_identifiers.stub!(:empty?).and_return(true)
        @openid_identifiers.stub!(:build).and_return(@openid_identifier)

        @user.stub!(:openid_identifiers).and_return(@openid_identifiers)
      end

      describe '保存に成功した場合' do
        before do
          @openid_identifier.should_receive(:save).and_return(true)
          post :apply_ident_url, :openid_identifier => {:url => @url}
        end

        it { response.should be_redirect  }
        it { flash[:notice].should_not be_nil }
      end

      describe '保存に失敗した場合' do
        before do
          @openid_identifier.should_receive(:save).and_return(false)

          post :apply_ident_url, :openid_identifier => {:url => @url}
        end

        it { assigns[:openid_identifier].should_not be_nil }
        it { response.should render_template('mypage/_manage_openid') }
        it { flash[:notice].should be_nil }
      end
    end
    describe '更新の場合' do
      before do
        @user = user_login

        @openid_identifier = stub_model(OpenidIdentifier, :user_id => @user.id)

        @openid_identifiers = mock('openid_identifiers')
        @openid_identifiers.stub!(:empty?).and_return(false)
        @openid_identifiers.stub!(:first).and_return(@openid_identifier)

        @user.stub!(:openid_identifiers).and_return(@openid_identifiers)
      end
      describe '保存に成功した場合' do
        before do
          @url = 'http://example.com'

          @openid_identifier.should_receive(:url=).with(@url)
          @openid_identifier.should_receive(:save).and_return(true)

          post :apply_ident_url, :openid_identifier => {:url => @url}
        end

        it { response.should be_redirect }
        it { flash[:notice].should_not be_nil }
      end
      describe '保存に失敗した場合' do
        before do
          @url = 'http://example.com'

          @openid_identifier.should_receive(:url=).with(@url)
          @openid_identifier.should_receive(:save).and_return(false)

          post :apply_ident_url, :openid_identifier => {:url => @url}
        end

        it { response.should render_template('mypage/_manage_openid') }
        it { assigns[:openid_identifier].should_not be_nil }
      end
    end
  end

  describe "GET /mypage/apply_ident_url" do
    before do
      get :apply_ident_url
    end
    it { response.should redirect_to(:action => :index)}
  end
end

describe MypageController, 'POST #update_profile' do
  before do
    @user = user_login
    @profiles = (1..2).map{|i| stub_model(UserProfileValue, :save! => true)}
    @user.stub!(:find_or_initialize_profiles).and_return(@profiles)
  end
  describe '保存に成功する場合' do
    before do
      @user.stub!(:attributes=)
      @user.should_receive(:save!)
    end

    it "userにパラメータからの値が設定されること" do
      @user.should_receive(:attributes=)
      post_update_profile
    end
    it "profileが設定されること" do
      @user.should_receive(:find_or_initialize_profiles).with({"1"=>"ほげ", "2"=>"ふが"}).and_return(@profiles)
      post_update_profile
    end
    it "profileがそれぞれ保存されること" do
      @profiles.each{ |profile| profile.should_receive(:save!) }
      post_update_profile
    end
    it "自分のプロフィール表示画面にリダイレクトされること" do
      post_update_profile
      response.should redirect_to(:action => 'profile')
    end
    it "flashメッセージ「ユーザ情報の更新に成功しました。」と登録されること" do
      post_update_profile
      flash[:notice].should == "ユーザ情報の更新に成功しました。"
    end
    def post_update_profile
      post :update_profile, {"user" => {"section"=>"開発"}, "profile_value" => {"1"=>"ほげ", "2"=>"ふが"}}
    end
  end
  describe '保存に失敗する場合' do
    before do
      @user.should_receive(:save!).and_raise(mock_record_invalid)
      controller.stub!(:current_user).and_return(@user)
    end
    it "編集画面を再度表示すること" do
      post :update_profile
      response.should render_template('mypage/_manage_profile')
    end
    it "２つのプロフィールにエラーが設定されている場合、２つのバリデーションエラーが設定されること" do
      errors = mock('errors', :full_messages => ["バリデーションエラーです"])
      @profiles.map{ |profile| profile.stub!(:errors).and_return(errors) }

      post :update_profile
      assigns[:error_msg].grep("バリデーションエラーです").size.should == 2
    end
    it "一つだけプロフィールにエラーが設定されている場合、１つのバリデーションエラーのみが設定されること" do
      errors = mock('errors', :full_messages => ["バリデーションエラーです"])
      @profiles.last.stub!(:errors).and_return(errors)

      post :update_profile
      assigns[:error_msg].grep("バリデーションエラーです").size.should == 1
    end
    it "プロフィールにエラーが無い場合、バリデーションエラーが設定されていないこと" do
      post :update_profile
      assigns[:error_msg].should == assigns[:user].errors.full_messages
    end
  end
end

describe MypageController, "POST /apply_password" do
  before do
    INITIAL_SETTINGS['login_mode'] = 'password'

    @user = user_login
    @user.should_receive(:change_password)
    @user.should_receive(:errors).and_return([])

    post :apply_password
  end
  it { response.should redirect_to(:action => :manage, :menu => :manage_password) }
end

describe MypageController, "GET /antenna_list" do
  before do
    user_login
    @result_text = 'result_text'
    controller.should_receive(:current_user_antennas_as_json).and_return(@result_text)
    get :antenna_list
  end
  it { response.should include_text(@result_text) }
end

describe MypageController, "#unify_feed_form" do
  before do
    @channel = mock('channel')
    @items = (1..5).map{|i| mock("item#{i}") }
    @feed = mock('feed', :channel => @channel, :items => @items)

    @title = "title"
    @limit = 1
  end

  # 1.8.6系で実行できないためAtomを利用できるバージョンでのみテストする
  if defined?(RSS::Atom::Feed)
    describe "feedがRSS:Rssの場合" do
      before do
        @channel.stub!(:title=)
        @feed.stub!(:is_a?).with(RSS::Rss).and_return(true)
      end
      it "titleが設定されること" do
        @channel.should_receive(:title=).with(@title)
        controller.send(:unify_feed_form, @feed, @title)
      end
      it "limit以下のアイテム数になること" do
        feed = controller.send(:unify_feed_form, @feed, @title, @limit)
        feed.items.size.should == @limit
      end
      it "is_a?(RSS::Atom::Feed)が呼ばれないこと" do
        @feed.should_not_receive(:is_a?).with(RSS::Atom::Feed)
        controller.send(:unify_feed_form, @feed, @title)
      end
    end
    describe "feedがRSS::Atomの場合" do
      describe "Atomが利用できるライブラリのバージョンの場合" do
        before do
          @channel.stub!(:title=)

          @feed.stub!(:is_a?).with(RSS::Rss).and_return(false)
          @feed.stub!(:is_a?).with(RSS::Atom::Feed).and_return(true)
          @feed.stub!(:to_rss).with("2.0").and_return(@feed)
        end
        it "AtomからRss2.0に変換されること" do
          @feed.should_receive(:to_rss).with("2.0").and_return(@feed)
          controller.send(:unify_feed_form, @feed)
        end
        it "titleが設定されること" do
          @channel.should_receive(:title=).with(@title)
          controller.send(:unify_feed_form, @feed, @title, @limit)
        end
        it "limit以下のアイテム数になること" do
          feed = controller.send(:unify_feed_form, @feed, @title, @limit)
          feed.items.size.should == @limit
        end
      end
    end
    describe "Atomが利用できないライブラリのバージョンでAtomを読み込んだ場合" do
      before do
        @feed.stub!(:is_a?).with(RSS::Rss).and_return(false)
        @feed.stub!(:is_a?).with(RSS::Atom::Feed).and_raise(NameError.new("uninitialized constant RSS::Atom", "RSS::Atom::Feed"))
      end
      it "ログにエラーが表示されること" do
        controller.logger.should_receive(:error).with("[Error] Rubyのライブラリが古いためAtom形式を変換できませんでした。")
        controller.send(:unify_feed_form, @feed)
      end
      it "nilが返されること" do
        controller.send(:unify_feed_form, @feed).should be_nil
      end
    end
  end
end

