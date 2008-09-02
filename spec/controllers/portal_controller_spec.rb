require File.dirname(__FILE__) + '/../spec_helper'

describe PortalController, 'GET /index' do
  before do
    unused_user_login
  end
  describe "entrance_next_actionが何もない時" do
    before do
      get :index
    end
    it { response.should be_success }
    it { response.should render_template('confirm') }
  end

  describe "entrance_next_actionが:registrationの場合" do
    before do
      @code = '111111'
      session[:user_code] = @code
      @user = mock_model(User)
      User.should_receive(:find_by_code).with(@code).and_return(@user)
      session[:entrance_next_action] = :registration
      get :index
    end
    it { response.should be_success }
    it { response.should render_template('registration') }
    it { assigns[:user].should == @user }
    it { assigns[:profile].should_not be_nil }
    it { assigns[:user_uid].should_not be_nil }
  end
end

describe PortalController, 'POST /apply' do
  before do
    unused_user_login
  end
  describe '正常に動作する場合' do
    before do
      user = create_user({ :status => 'UNUSED' })
      @user = User.find_by_id(user.id)
      @user.should_receive(:status=).with('ACTIVE')

      controller.stub!(:current_user).and_return(@user)

      post :apply, { "user"=> {"extension"=>"000000", "introduction"=>"00000", "section"=>"開発"},
        "profile"=>{"birth_month"=>"1", "join_year"=>"2008", "blood_type"=>"1", "address_1"=>"1", "alma_mater"=>"非公開", "birth_day"=>"1", "gender_type"=>"1", "address_2"=>"非公開", "introduction"=>"", "hometown"=>"1"},
        "user_uid"=>{"uid"=>"hogehoge"},
        "new_address_2"=>"", "write_profile"=>"true", "new_section"=>"", "new_alma_mater"=>"" }
    end

    it { response.should be_redirect }
    it { assigns[:user].should_not be_nil }
    it { assigns[:profile].should_not be_nil }
    it { assigns[:user_uid].should_not be_nil }
  end

  describe 'Userの保存に失敗する場合' do
    it "失敗の処理をする"
  end
end

describe PortalController, '#make_profile' do
  before do
    unused_user_login
    @portal_controller = PortalController.new
    @params = {:new_alma_mater => '', :new_address_2 => '', :profile => {}}
    @portal_controller.stub!(:params).and_return(@params)
    @profile = mock_model(UserProfile)
    @profile.stub!('hobby=')
    @profile.stub!('disclosure=')
  end
  describe 'new_alma_materが空じゃない場合' do
    before do
      @new_alma_mater = 'new_alma_mater'
      @params = @params.merge({:new_alma_mater => @new_alma_mater})
      @portal_controller.stub!(:params).and_return(@params)
    end
    it 'profileのalma_materに値が設定されること' do
      @params[:profile].should_receive('[]=').with(:alma_mater, @new_alma_mater)
      @portal_controller.send('make_profile')
    end
  end
  describe 'new_address_2が空じゃない場合' do
    before do
      @new_address_2 = 'new_address_2'
      @params = @params.merge({:new_address_2 => @new_address_2})
      @portal_controller.stub!(:params).and_return(@params)
    end
    it 'profileのaddress_2に値が設定されること' do
      @params[:profile].should_receive('[]=').with(:address_2, @new_address_2)
      @portal_controller.send('make_profile')
    end
  end
  describe 'write_profileが指定されている場合' do
    before do
      @params = @params.merge({:write_profile => '1'})
      @portal_controller.stub!(:params).and_return(@params)
    end
    it 'UserProfileがparamsのprofileを元に作成されること' do
      UserProfile.should_receive(:new).with(@params[:profile]).and_return(@profile)
      @portal_controller.send('make_profile')
    end
    it 'UserProfileのdisclosureにtrueが設定されること' do
      @profile.should_receive('disclosure=').with(true)
      UserProfile.should_receive(:new).with(@params[:profile]).and_return(@profile)
      @portal_controller.send('make_profile')
    end
  end
  describe 'write_profileが指定されていない場合' do
    before do
      @params = @params.merge({:write_profile => nil})
      @portal_controller.stub!(:params).and_return(@params)
    end
    it 'UserProfileが作成されること' do
      UserProfile.should_receive(:new).and_return(@profile)
      @portal_controller.send('make_profile')
    end
    it 'UserProfileのdisclosureにfalseが設定されること' do
      @profile.should_receive('disclosure=').with(false)
      UserProfile.should_receive(:new).and_return(@profile)
      @portal_controller.send('make_profile')
    end
  end
  describe 'hobbiesに入力がある場合' do
    before do
      @hobbies = ['neru', 'taberu']
      @params = @params.merge({:hobbies => @hobbies})
      @portal_controller.stub!(:params).and_return(@params)
    end
    it 'profileのhobbyに設定されること' do
      @profile.should_receive('hobby=').twice
      UserProfile.should_receive(:new).and_return(@profile)
      @portal_controller.send('make_profile')
    end
  end
end

def unused_user_login
  session[:user_code] = '111111'
  session[:prepared] = true
  u = stub_model(User)
  u.stub!(:admin).and_return(false)
  u.stub!(:active?).and_return(false)
  u.stub!(:unused?).and_return(true)
  if defined? controller
    controller.stub!(:current_user).and_return(u)
  else
    # helperでも使えるように
    stub!(:current_user).and_return(u)
  end
  u
end
