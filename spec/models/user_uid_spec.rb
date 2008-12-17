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

describe UserUid, '.validation_error_message' do
  describe 'validなuidの場合' do
    it 'nilを返すこと' do
      UserUid.validation_error_message(SkipFaker.rand_char(4)).should be_nil
    end
  end
  describe 'invalidなuidの場合' do
    it 'エラーメッセージを返すこと' do
      UserUid.validation_error_message(SkipFaker.rand_char(3)).should_not be_nil
    end
  end
end

describe UserUid, '.validates_length_of' do
  before do
    @minimum = INITIAL_SETTINGS['user_code_minimum_length'].to_i
  end
  describe "uidが最小値未満の文字数の場合" do
    before do
      @user_uid = create_user_uid(:uid => SkipFaker.rand_char(@minimum - 1))
      @user_uid.valid?
    end
    it 'uidが短すぎる旨のエラーとなること' do
      @user_uid.errors['uid'].should == "Uid is too short (minimum is #{@minimum} characters)"
    end
  end
  describe "uidが最小値と等しい文字数の場合" do
    before do
      @user_uid = create_user_uid(:uid => SkipFaker.rand_char(@minimum))
      @user_uid.valid?
    end
    it 'エラーとならないこと' do
      @user_uid.errors['uid'].should be_nil
    end
  end
  describe 'uidが30文字の場合' do
    before do
      @user_uid = create_user_uid(:uid => SkipFaker.rand_char(30))
      @user_uid.valid?
    end
    it 'エラーとならないこと' do
      @user_uid.errors['uid'].should be_nil
    end
  end
  describe 'uidが31文字の場合' do
    before do
      @user_uid = create_user_uid(:uid => SkipFaker.rand_char(31))
      @user_uid.valid?
    end
    it 'uidが長すぎる旨のエラーとなること' do
      @user_uid.errors['uid'].should == 'Uid is too long (maximum is 30 characters)'
    end
  end
  def create_user_uid options = {}
    UserUid.new({:uid => SkipFaker.rand_char, :uid_type => 'MASTER'}.merge(options))
  end
end
