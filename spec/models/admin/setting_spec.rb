require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

#class Admin::Setting < ActiveRecord::Base
#  attr_accessor :cached_settings
#  attr_accessor :cached_cleared_on
#end
Admin::Setting.class_eval do
  def self.cached_settings
    @cached_settings
  end
  def self.cached_settings=(val)
    @cached_settings = val
  end
end

describe Admin::Setting, '@@available_settings' do
  it '設定ファイルがロードされていること' do
    Admin::Setting.available_settings.should_not be_nil
  end
  it '型がHashであること' do
    Admin::Setting.available_settings.should be_is_a(Hash)
  end
end

describe Admin::Setting, '.[]' do
  describe '引数に一致する値がキャッシュされている場合' do
    before do
      @cached_key = 'hoge'
      @val = 'hogeval'
      Admin::Setting.cached_settings = {@cached_key => @val}
    end
    it { Admin::Setting[@cached_key].should == @val }
  end
  describe '引数に一致する値がキャッシュされていない場合' do
    before do
      Admin::Setting.cached_settings = {}
      @setting = mock_model(Admin::Setting, :value => 'value')
      Admin::Setting.should_receive(:find_or_default).and_return(@setting)
    end
    it { Admin::Setting['hige'].should == @setting.value }
  end
end

describe Admin::Setting, '.[]=' do
  before do
    @setting = mock_model(Admin::Setting)
    @setting.should_receive(:value=)
    Admin::Setting.should_receive(:find_or_default).and_return(@setting)
    Admin::Setting.cached_settings = {}
  end
  describe '保存に成功する場合' do
    before do
      @setting.should_receive(:save).and_return(true)
      @value = mock('hoge')
    end
    it 'Admin::Settingのオブジェクトが返却されること' do
      Admin::Setting.[]=(:hoge, @value).should == @setting
    end
  end
end

describe Admin::Setting, '@@available_settingsの要素に対するaccesser' do
end

describe Admin::Setting, '.check_cache' do
  before do
    @now = Time.now
    @before = Time.now - 1.year
    Time.stub!(:now).and_return(@now)
  end
  describe '新しく更新されていた場合' do
    before do
      Admin::Setting.instance_variable_set(:@cached_cleared_on, @before)
      Admin::Setting.should_receive(:maximum).and_return(@now)
      logger = mock('logger')
      logger.stub!(:info)
      Admin::Setting.should_receive(:logger).twice.and_return(logger)
      Admin::Setting.check_cache
    end
    it "更新時間が新しくなる" do
      Admin::Setting.instance_variable_get(:@cached_cleared_on).should == @now
    end
    it "ログが出力される" do
    end
  end
  describe "更新されていない場合" do
    before do
      Admin::Setting.instance_variable_set(:@cached_cleared_on, @now)
      Admin::Setting.should_receive(:maximum).and_return(@before)
      Admin::Setting.should_not_receive(:logger)
      Admin::Setting.check_cache
    end
    it "更新時間が新しくならない" do
      Admin::Setting.instance_variable_get(:@cached_cleared_on).should == @now
    end
    it "ログが出力されない" do
    end
  end
end

describe Admin::Setting, '.find_or_default' do
  describe '@@available_settingsが引数のキーを持っていない場合' do
    before do
      Admin::Setting.available_settings.should_receive(:has_key?).and_return(false)
    end
    it '例外が送出されること' do
      lambda do
        Admin::Setting.send(:find_or_default, 'hoge')
      end.should raise_error
    end
  end
  describe '@@available_settingsが引数のキーを持っている場合' do
    before do
      Admin::Setting.available_settings.should_receive(:has_key?).and_return(true)
    end
    describe 'dbにデータがある場合' do
      before do
        @setting = mock_model(Admin::Setting)
        Admin::Setting.should_receive(:find_by_name).and_return(@setting)
      end
      it 'dbのデータが返ること' do
        Admin::Setting.send(:find_or_default, 'hoge').should == @setting
      end
    end
    describe 'dbにデータがない場合' do
      before do
        @key = 'hoge'
        Admin::Setting.available_settings[@key] = {}
        Admin::Setting.should_receive(:find_by_name).and_return(nil)
        Admin::Setting.stub!(:new).and_return({})
      end
      it 'newが呼ばれること' do
        Admin::Setting.should_receive(:new)
        Admin::Setting.send(:find_or_default, @key)
      end
      it 'newの戻り値が返ること' do
        Admin::Setting.send(:find_or_default, @key)
      end
      it 'newの戻り値のvalueが@@available_settingsのdefault値になっていること' do
        Admin::Setting.should_receive(:new).with({:name => @key, :value => Admin::Setting.available_settings[@key]['default']})
        Admin::Setting.send(:find_or_default, @key)
      end
    end
  end
end
