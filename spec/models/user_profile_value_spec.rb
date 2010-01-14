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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe UserProfileValue, "マスタのrequired" do
  before do
    @master = create_user_profile_master(:input_type => 'text_field', :name => "phone_no")
    @value = UserProfileValue.new(:user_profile_master => @master, :user => stub_model(User))
  end
  describe "必須の条件のマスタの場合" do
    before do
      @master.required = true
      @master.save
    end
    it "項目が空の時、バリデーションエラーとなること" do
      @value.should_not be_valid
    end
    it "項目が空でない時、バリデーションエラーとならないこと" do
      @value.value = "value"
      @value.should be_valid
    end
  end
  describe "必須でない条件のマスタの場合" do
    before do
      @master.required = false
      @master.save
    end
    it "項目が空の時、バリデーションエラーとならない" do
      @value.should be_valid
    end
    it "項目が空でない時、バリデーションエラーとならないこと" do
      @value.value = "value"
      @value.should be_valid
    end

  end
end

describe UserProfileValue, "マスタのinput_type" do
  before do
    @master = create_user_profile_master(:input_type => 'number_and_hyphen_only', :name => "phone_no")
    @value = UserProfileValue.new(:user_profile_master => @master, :user => stub_model(User))
  end
  describe "input_typeがnumber_and_hyphen_onlyの時" do
    describe "valueが数字とハイフンのみの場合" do
      it "バリデーションエラーとならないこと" do
        @value.value = "000-000-0000"
        @value.should be_valid
      end
    end
    describe "valueが英字の場合" do
      it "バリデーションエラーとなること" do
        @value.value = "aaa-aaa-aaaa"
        @value.should_not be_valid
      end
    end
  end
  describe "input_typeがradioの場合" do
    before do
      @master.input_type = "radio"
      @master.option_values = "select1,select2,select3"
      @master.save
    end
    describe "valueがoption_valuesに含まれる場合" do
      it "バリデーションエラーとならないこと" do
        @value.value = "select2"
        @value.should be_valid
      end
    end
    describe "valueがoption_valuesに含まれない場合" do
      it "バリデーションエラーとなること" do
        @value.value = "unselect"
        @value.should_not be_valid
      end
    end
  end
end
