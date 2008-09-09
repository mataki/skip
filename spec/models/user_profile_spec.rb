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

describe UserProfile, '.grouped_sections' do
  before do
    create_user :user_profile_options => {:email => SkipFaker.email, :section => 'Programmer', :disclosure => true}, :user_uid_options => {:uid => SkipFaker.rand_num(6)}
    create_user :user_profile_options => {:email => SkipFaker.email, :section => 'Programmer', :disclosure => true}, :user_uid_options => {:uid => SkipFaker.rand_num(6)}
    create_user :user_profile_options => {:email => SkipFaker.email, :section => 'Tester', :disclosure => true}, :user_uid_options => {:uid => SkipFaker.rand_num(6)}
  end
  it {UserProfile.grouped_sections.size.should == 2}
end

describe UserProfile, '#attributes_for_registration' do
  before do
    @user_profile = UserProfile.new
    @params = {:new_alma_mater => '', :new_address_2 => '', :new_section => '', :profile => {:self_introduction => ''}}
  end
  describe 'new_sectionが空じゃない場合' do
    before do
      @new_section = 'new_section'
      @params = @params.merge!({:new_section => @new_section})
    end
    it 'profileのsectionに値が設定されること' do
      @user_profile.should_receive('section=').with(@new_section.upcase)
      @user_profile.attributes_for_registration(@params)
    end
  end
  describe 'new_alma_materが空じゃない場合' do
    before do
      @new_alma_mater = 'new_alma_mater'
      @params = @params.merge({:new_alma_mater => @new_alma_mater})
    end
    it 'profileのalma_materに値が設定されること' do
      @user_profile.should_receive('alma_mater=').with(@new_alma_mater)
      @user_profile.attributes_for_registration(@params)
    end
  end
  describe 'new_address_2が空じゃない場合' do
    before do
      @new_address_2 = 'new_address_2'
      @params = @params.merge({:new_address_2 => @new_address_2})
    end
    it 'profileのaddress_2に値が設定されること' do
      @user_profile.should_receive('address_2=').with(@new_address_2)
      @user_profile.attributes_for_registration(@params)
    end
  end
  describe 'write_profileが指定されている場合' do
    before do
      @params = @params.merge({:write_profile => '1'})
    end
    it 'UserProfileのdisclosureにtrueが設定されること' do
      @user_profile.should_receive('disclosure=').with(true)
      @user_profile.attributes_for_registration(@params)
    end
  end
  describe 'write_profileが指定されていない場合' do
    before do
      @params = @params.merge({:write_profile => nil})
    end
    it 'UserProfileのdisclosureにfalseが設定されること' do
      @user_profile.should_receive('disclosure=').with(false)
      @user_profile.attributes_for_registration(@params)
    end
  end
  describe 'hobbiesに入力がある場合' do
    before do
      @hobbies = ['neru', 'taberu']
      @params = @params.merge({:hobbies => @hobbies})
    end
    it 'profileのhobbyに設定されること' do
      @user_profile.should_receive('hobby=').twice
      @user_profile.attributes_for_registration(@params)
    end
  end
end

