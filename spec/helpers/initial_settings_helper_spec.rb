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

describe InitialSettingsHelper, "#login_mode?" do
  describe "固定RPモードの場合" do
    before do
      INITIAL_SETTINGS['login_mode'] = 'rp'
      INITIAL_SETTINGS['fixed_op_url'] = 'http://op.openskip.org/'
    end
    it { helper.login_mode?(:password).should be_false }
    it { helper.login_mode?(:free_rp).should be_false }
    it { helper.login_mode?(:fixed_rp).should be_true }
  end
  describe "フリーRPモードの場合" do
    before do
      INITIAL_SETTINGS['login_mode'] = 'rp'
      INITIAL_SETTINGS['fixed_op_url'] = nil
    end
    it { helper.login_mode?(:password).should be_false }
    it { helper.login_mode?(:free_rp).should be_true }
    it { helper.login_mode?(:fixed_rp).should be_false }
  end
  describe "パスワードモードの場合" do
    before do
      INITIAL_SETTINGS['login_mode'] = 'password'
    end
    it { helper.login_mode?(:password).should be_true }
    it { helper.login_mode?(:free_rp).should be_false }
    it { helper.login_mode?(:fixed_rp).should be_false }
  end
end

describe InitialSettingsHelper, '#enable_activate?' do
  describe 'パスワードモード かつ ユーザ登録可 かつ メール機能有効の場合' do
    before do
      INITIAL_SETTINGS['login_mode'] = 'password'
      Admin::Setting.stub!(:stop_new_user).and_return(false)
      Admin::Setting.stub!(:mail_function_setting).and_return(true)
    end
    it { helper.enable_activate?.should be_true }
  end
  describe '固定RPモードの場合' do
    before do
      INITIAL_SETTINGS['login_mode'] = 'rp'
      INITIAL_SETTINGS['fixed_op_url'] = 'http://op.openskip.org/'
    end
    it { helper.enable_activate?.should be_false }
  end
  describe 'フリーRPモードの場合' do
    before do
      INITIAL_SETTINGS['login_mode'] = 'rp'
      INITIAL_SETTINGS['fixed_op_url'] = nil
    end
    it { helper.enable_activate?.should be_false }
  end
  describe 'ユーザ登録停止の場合' do
    before do
      Admin::Setting.stub!(:stop_new_user).and_return(true)
    end
    it { helper.enable_activate?.should be_false }
  end
  describe 'メール機能無効の場合' do
    before do
      Admin::Setting.stub!(:mail_function_setting).and_return(false)
    end
    it { helper.enable_activate?.should be_false }
  end
end

describe InitialSettingsHelper, '#enable_signup?' do
  describe 'パスワードモードの場合' do
    before do
      INITIAL_SETTINGS['login_mode'] = 'password'
    end
    it { helper.enable_signup?.should be_true }
  end
  describe '固定RPモードの場合' do
    before do
      INITIAL_SETTINGS['login_mode'] = 'rp'
      INITIAL_SETTINGS['fixed_op_url'] = 'http://op.openskip.org/'
    end
    it { helper.enable_signup?.should be_false }
  end
  describe 'フリーRPモードの場合' do
    before do
      INITIAL_SETTINGS['login_mode'] = 'rp'
      INITIAL_SETTINGS['fixed_op_url'] = nil
    end
    it { helper.enable_signup?.should be_false }
  end
end

describe InitialSettingsHelper, '#enable_forgot_password?' do
  describe 'パスワードモード かつ メール機能有効の場合' do
    before do
      INITIAL_SETTINGS['login_mode'] = 'password'
      Admin::Setting.stub!(:mail_function_setting).and_return(true)
    end
    it { helper.enable_forgot_password?.should be_true }
  end
  describe '固定RPモードの場合' do
    before do
      INITIAL_SETTINGS['login_mode'] = 'rp'
      INITIAL_SETTINGS['fixed_op_url'] = 'http://op.openskip.org/'
    end
    it { helper.enable_forgot_password?.should be_false }
  end
  describe 'フリーRPモードの場合' do
    before do
      INITIAL_SETTINGS['login_mode'] = 'rp'
      INITIAL_SETTINGS['fixed_op_url'] = nil
    end
    it { helper.enable_forgot_password?.should be_false }
  end
  describe 'メール機能無効の場合' do
    before do
      Admin::Setting.stub!(:mail_function_setting).and_return(false)
    end
    it { helper.enable_forgot_password?.should be_false }
  end
end

describe InitialSettingsHelper, '#enable_forgot_openid?' do
  describe 'フリーRPモードの場合 かつ メール機能有効の場合' do
    before do
      INITIAL_SETTINGS['login_mode'] = 'rp'
      INITIAL_SETTINGS['fixed_op_url'] = nil
      Admin::Setting.stub!(:mail_function_setting).and_return(true)
    end
    it { helper.enable_forgot_openid?.should be_true }
  end
  describe 'パスワードモードの場合' do
    before do
      INITIAL_SETTINGS['login_mode'] = 'password'
    end
    it { helper.enable_forgot_openid?.should be_false }
  end
  describe '固定RPモードの場合' do
    before do
      INITIAL_SETTINGS['login_mode'] = 'rp'
      INITIAL_SETTINGS['fixed_op_url'] = 'http://op.openskip.org/'
    end
    it { helper.enable_forgot_openid?.should be_false }
  end
  describe 'メール機能無効の場合' do
    before do
      Admin::Setting.stub!(:mail_function_setting).and_return(false)
    end
    it { helper.enable_forgot_openid?.should be_false }
  end
end
