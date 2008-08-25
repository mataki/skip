require File.dirname(__FILE__) + '/../spec_helper'

describe PortalController, 'POST /apply' do
  before do
    user_login
  end
  describe '正常に動作する場合' do
#    it '@userが作られること'
#    it 'user_uidが作られること'
#    it '@profileが作られること'
#    it 'Userの保存に成功すること'
#    it 'Antennaの保存に成功すること'
#    it '初期エントリが作成されること'
#    it 'UserAccessの保存に成功すること'
#    it 'signup確認のメールが送信されること'
    it 'welcome画面に遷移すること'
  end
  describe 'Userの保存に失敗する場合' do
  end
end

describe PortalController, '#make_profile' do
  before do
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

describe PortalController, '#make_user_uid' do
  it '正常に動作すること'
end
