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

  belongs_to :user

  validates_presence_of :email, :message => _('is mandatory.')
  validates_length_of :email, :maximum => 50, :message => _('accepts 50 or less characters only.')
  validates_format_of :email, :message => _('requires proper format.'), :with => /^([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})$/
  validates_uniqueness_of :email, :message => _('has already been registered.')

  validates_length_of :alma_mater, :maximum=>20, :message =>_('accepts 20 or less characters only.'), :allow_nil => true

  validates_length_of :address_2,  :maximum=>100, :message =>_('accepts 100 or less characters only.'), :allow_nil => true

  N_('UserProfile|Alma mater')
  N_('UserProfile|Address 2')

  N_('UserProfile|Disclosure|true')
  N_('UserProfile|Disclosure|false')

  class << self
    HUMANIZED_ATTRIBUTE_KEY_NAMES = {
      "alma_mater" => "Alma mater",
      "address_2" => "Address 2"
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
    return _("%{month}/%{day}") % {:month => self.birth_month.to_s, :day => self.birth_day.to_s}
  end

  # 住所を返す
  def address
    return '' if self.address_1.blank?
    address = TODOUHUKEN[self.address_1]
    #Fixme
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

  # Viewで使う所属一覧（セレクトボタン用）
  def self.grouped_sections
    all(:select => "section", :group => "section").collect { |user_profile| user_profile.section }
  end

  def attributes_for_registration params
    self.attributes = params[:profile]
    self.section = params[:new_section].tr('ａ-ｚＡ-Ｚ１-９','a-zA-Z1-9').upcase unless params[:new_section].empty?
    self.alma_mater = params[:new_alma_mater] unless SkipUtil.jstrip(params[:new_alma_mater]).empty?
    self.address_2 = params[:new_address_2] unless SkipUtil.jstrip(params[:new_address_2]).empty?
    self.self_introduction = SkipUtil.jstrip(params[:profile][:self_introduction])
    self.hobby = ''
    if (params[:hobbies] && params[:hobbies].size > 0 )
      self.hobby = params[:hobbies].join(',') + ','
    end
    self.disclosure = params[:write_profile] ? true : false
  end
end
