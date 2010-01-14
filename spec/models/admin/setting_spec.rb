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

describe Admin::Setting, 'validate' do
  describe 'nameがcustom_password_strength_regexなvalue' do
    describe 'nameがpassword_strengthなvalueがcustomの場合' do
      before do
        Admin::Setting.should_receive(:password_strength).and_return('custom')
      end
      describe '入力がない場合' do
        before do
          @setting = Admin::Setting.[]=('custom_password_strength_regex', '')
        end
        it '必須エラーとなること' do
          @setting.errors['value'].should_not be_nil
        end
      end
      describe '入力がある場合' do
        before do
          @setting = Admin::Setting.[]=('custom_password_strength_regex', 'skip')
        end
        it '必須エラーとならないこと' do
          @setting.errors['value'].should be_nil
        end
      end
    end
    describe 'nameがpassword_strengthなvalueがcustom以外の場合' do
      before do
        Admin::Setting.should_receive(:password_strength).and_return('middle')
      end
      describe '入力がない場合' do
        before do
          @setting = Admin::Setting.[]=('custom_password_strength_regex', '')
        end
        it '必須エラーとならないこと' do
          @setting.errors['value'].should be_nil
        end
      end
    end
  end

  describe 'nameがcustom_password_strength_validation_messageなvalue' do
    describe 'nameがpassword_strengthなvalueがcustomの場合' do
      before do
        Admin::Setting.should_receive(:password_strength).and_return('custom')
      end
      describe '入力がない場合' do
        before do
          @setting = Admin::Setting.[]=('custom_password_strength_validation_message', '')
        end
        it '必須エラーとなること' do
          @setting.errors['value'].should_not be_nil
        end
      end
      describe '入力がある場合' do
        before do
          @setting = Admin::Setting.[]=('custom_password_strength_validation_message', 'error')
        end
        it '必須エラーとならないこと' do
          @setting.errors['value'].should be_nil
        end
      end
    end
  end

  describe 'formatがregexなvalue' do
    before do
      Admin::Setting.available_settings['regex_setting'] = {}
    end
    describe '設定項目のformatがregexの場合' do
      before do
        Admin::Setting.available_settings['regex_setting']['format'] = 'regex'
      end
      describe '正規表現として妥当な値が設定されている場合' do
        before do
          @setting = Admin::Setting.[]=('regex_setting', 'skip')
        end
        it '正規表現が不正なエラーが設定されないこと' do
          @setting.errors['value'].should be_nil
        end
      end
      describe '正規表現として不正な値が設定されている場合' do
        before do
          @setting = Admin::Setting.[]=('regex_setting', '++')
        end
        it '正規表現が不正なエラーが設定されること' do
          @setting.errors['value'].should_not be_nil
        end
      end
    end
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

describe Admin::Setting, '.password_strength_regex' do
  describe 'パスワード強度がlowの場合' do
    before do
      Admin::Setting.should_receive(:password_strength).and_return('low')
    end
    it '英数字記号6桁以上の入力を受け入れる正規表現を返すこと' do
      Admin::Setting.password_strength_regex.should == /^[a-zA-Z0-9!@#\$%\^&\*\?_~]{6,}$/
    end
  end
  describe 'パスワード強度がmiddleの場合' do
    before do
      Admin::Setting.should_receive(:password_strength).and_return('middle')
    end
    it '英数字記号8桁以上(小文字、大文字、数字が1文字ずつ含まれる)を受け入れる正規表現を返すこと' do
      Admin::Setting.password_strength_regex.should == /(?!^[^a-z]*$)(?!^[^A-Z]*$)(?!^[^0-9]*$)^[a-zA-Z0-9!@#\$%\^&\*\?_~]{8,}$/
    end
  end
  describe 'パスワード強度がhighの場合' do
    before do
      Admin::Setting.should_receive(:password_strength).and_return('high')
    end
    it '英数字記号8桁以上(小文字、大文字、数字、記号が1文字ずつ含まれる)を受け入れる正規表現を返すこと' do
      Admin::Setting.password_strength_regex.should == /(?!^[^!@#\$%\^&\*\?_~]*$)(?!^[^a-z]*$)(?!^[^A-Z]*$)(?!^[^0-9]*$)^[a-zA-Z0-9!@#\$%\^&\*\?_~]{8,}$/
    end
  end
  describe 'パスワード強度がcustomの場合' do
    before do
      Admin::Setting.should_receive(:password_strength).and_return('custom')
      Admin::Setting.should_receive(:custom_password_strength_regex).and_return('custom_password_strength_regex')
    end
    it 'ユーザ定義のパスワード強度の正規表現を返すこと' do
      Admin::Setting.password_strength_regex.should == /custom_password_strength_regex/
    end
  end
  describe 'パスワード強度が不明の場合' do
    before do
      Admin::Setting.should_receive(:password_strength).and_return(nil)
    end
    it '英数字記号8桁以上(小文字、大文字、数字が1文字ずつ含まれる)を受け入れる正規表現を返すこと' do
      Admin::Setting.password_strength_regex.should == /(?!^[^a-z]*$)(?!^[^A-Z]*$)(?!^[^0-9]*$)^[a-zA-Z0-9!@#\$%\^&\*\?_~]{8,}$/
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
