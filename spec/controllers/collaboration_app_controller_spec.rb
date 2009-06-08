require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe CollaborationAppController , 'GET /feed' do
  before do
    @current_user = user_login
  end
  it '設定されているパスに対してリソースの取得を試みること' do
    UserOauthAccess.should_receive(:resource).with('wiki', @current_user, 'path.rss').and_return('body')
    get :feed, :app_name => 'wiki', :path => 'path.rss', :gid => nil
  end
  it 'リクエストクエリにgidが含まれている場合はskip_gidパラメタ付きでリソースの取得を試みること' do
    UserOauthAccess.should_receive(:resource).with('wiki', @current_user, 'path.rss?skip_gid=gid').and_return('body')
    get :feed, :app_name => 'wiki', :path => 'path.rss', :gid => 'gid'
  end
  describe 'リソースの取得に成功する場合' do
    it 'feedが描画されること' do
      UserOauthAccess.stub!(:resource).and_yield(true, 'success_body')
      get :feed
      response.should render_template('feed')
    end
  end
  describe 'リソースの取得に失敗する場合' do
    it '「取得できませんでした。」と表示されること' do
      UserOauthAccess.stub!(:resource).and_yield(false, 'failuer_body')
      get :feed
      response.body.should == '取得できませんでした。'
    end
  end
end
