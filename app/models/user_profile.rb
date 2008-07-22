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

class UserProfile < ActiveRecord::Base

  include Types::Todouhuken
  include Types::Gender
  include Types::Blood
  include Types::Hobby

  validates_length_of :alma_mater, :maximum=>20, :message =>'は20文字以内で入力してください'
  validates_length_of :address_2,  :maximum=>100, :message =>'は100文字以内で入力してください'

  class << self
    HUMANIZED_ATTRIBUTE_KEY_NAMES = {
      "alma_mater" => "出身校",
      "address_2" => "現住所２"
    }
    def human_attribute_name(attribute_key_name)
      HUMANIZED_ATTRIBUTE_KEY_NAMES[attribute_key_name] || super
    end
  end


  # 性別を返す.
  def gender
    return GENDER[self.gender_type]
  end

  # 血液型を返す.
  def blood
    return BLOOD[self.blood_type]
  end

  # 出身地を返す.
  def hometown_name
    return TODOUHUKEN[self.hometown]
  end

  # 誕生日を返す
  def birth_month_day
    return self.birth_month.to_s + '月' + self.birth_day.to_s + '日'
  end

  # 住所を返す
  def address
    address = TODOUHUKEN[self.address_1]
    address = address + ' ' + self.address_2 unless self.address_2 == "非公開"
    return address
  end

  # Viewで使う性別一覧（ラジオボタン用）
  def self.select_gender_type
    return GENDER.collect{ |key, val| [val, key] }
  end

  # Viewで使う入社年度一覧（セレクトボタン用）
  def self.select_join_year
    return (1970..Date.today.year).to_a.reverse!
  end

  # Viewで使う血液型一覧（ラジオボタン用）
  def self.select_blood_type
    return BLOOD.collect{ |key, val| [val, key] }
  end

  # Viewで使う都道府県一覧（セレクトボタン用）
  def self.select_todouhuken
    return TODOUHUKEN.keys.sort.collect{|key| [TODOUHUKEN[key],key] }
  end

  # Viewで使う出身校一覧（セレクトボタン用）
  def self.select_alma_mater
    list = self.find(:all,
                     :select => "alma_mater",
                     :group => "alma_mater").collect { |profile| profile.alma_mater }
    list.insert(0, "非公開") unless list.include?("非公開")
    return list
  end

  # Viewで使う住所２一覧（セレクトボタン用）
  def self.select_address_2
    list = self.find(:all,
                     :select => "address_2",
                     :group => "address_2").collect { |profile| profile.address_2 }
    list.insert(0, "非公開") unless list.include?("非公開")
    return list
  end

  # デフォルトで用意した趣味の一覧をかえす
  def self.hobbies
    return DEFAULT_HOBBIES
  end

  # 引数の「趣味」が自分の趣味かどうかを判定する
  def check_hobby name
    self.hobby.include?(name+",") if self.hobby
  end

  # デフォルト値つきでインスタンス生成
  def self.new_default
    self.new(:gender_type => MAN,
             :blood_type => A,
             :hobby => "",
             :alma_mater => "非公開",
             :address_2 => "非公開")
  end
end
