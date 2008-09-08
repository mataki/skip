require File.dirname(__FILE__) + '/../spec_helper'

describe PortalController, 'GET /index' do
  before do
    @user = unused_user_login
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
    @user = unused_user_login
    controller.stub!(:make_profile).and_return(@user.user_profile)
  end
  describe '正常に動作する場合' do
    describe '新しい部署が入力されている場合' do
      before do
        @user.should_receive(:status=).with('ACTIVE')
        @user.user_profile.should_receive(:save!)
        @user.should_receive(:save!)

        controller.stub!(:current_user).and_return(@user)

        post :apply, {"profile"=>{"email"=>"example@skip.org", "extension"=>"000000", "introduction"=>"00000", "section"=>"開発", "birth_month"=>"1", "join_year"=>"2008", "blood_type"=>"1", "address_1"=>"1", "alma_mater"=>"非公開", "birth_day"=>"1", "gender_type"=>"1", "address_2"=>"非公開", "introduction"=>"", "hometown"=>"1"},
          "user_uid"=>{"uid"=>"hogehoge"},
          "new_address_2"=>"", "write_profile"=>"true", "new_section"=>"営業", "new_alma_mater"=>"" }
      end

      it { response.should be_redirect }
      it { assigns[:user].should_not be_nil }
      it { assigns[:profile].should_not be_nil }
      it { assigns[:user_uid].should_not be_nil }
    end
    describe '新しい部署が入力されていない場合' do
    end
  end

  describe 'Userの保存に失敗する場合' do
    it "失敗の処理をする"
  end
end

describe PortalController, '#make_profile' do
  before do
    @user = unused_user_login
    @profile = stub_model(UserProfile)
    @user.stub!(:user_profile).and_return(@profile)
    @portal_controller = PortalController.new
    @portal_controller.stub!(:current_user).and_return(@user)
    @params = {:new_alma_mater => '', :new_address_2 => '', :new_section => '', :profile => {}}
    @portal_controller.stub!(:params).and_return(@params)
  end
  describe 'new_sectionが空じゃない場合' do
    before do
      @new_section = 'new_section'
      @params = @params.merge!({:new_section => @new_section})
      @portal_controller.stub!(:params).and_return(@params)
    end
    it 'profileのsectionに値が設定されること' do
      @params[:profile].should_receive('[]=').with(:section, @new_section.upcase)
      @portal_controller.send('make_profile')
    end
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
    it '必須項目が設定されること' do
      @profile.should_receive('section=')
      @profile.should_receive('extension=')
      @profile.should_receive('self_introduction=')
      @portal_controller.send('make_profile')
    end
    it 'UserProfileがparamsのprofileで上書きされること' do
      @profile.should_receive('attributes=').with(@params[:profile])
      @user.should_receive(:user_profile).and_return(@profile)
      @portal_controller.send('make_profile')
    end
    it 'UserProfileのdisclosureにtrueが設定されること' do
      @profile.should_receive('disclosure=').with(true)
      @portal_controller.send('make_profile')
    end
  end
  describe 'write_profileが指定されていない場合' do
    before do
      @params = @params.merge({:write_profile => nil})
      @portal_controller.stub!(:params).and_return(@params)
    end
    it 'UserProfileがparamsのprofileで上書きされないこと' do
      @profile.should_not_receive('attributes=')
      @user.should_receive(:user_profile).and_return(@profile)
      @portal_controller.send('make_profile')
    end
    it 'UserProfileのdisclosureにfalseが設定されること' do
      @profile.should_receive('disclosure=').with(false)
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
      @portal_controller.send('make_profile')
    end
  end
end

