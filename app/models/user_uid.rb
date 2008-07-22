# SKIP(Social Knowledge & Innovation Platform)
# Copyright (C) 2008  TIS Inc.
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

class UserUid < ActiveRecord::Base
  belongs_to :user

  UID_TYPE = {
    :master => 'MASTER',
    :nickname => 'NICKNAME'
  }

  UID_MIN_LENGTH = 4
  UID_MAX_LENGTH = 31
  UID_FORMAT_REGEX = /^[a-zA-Z0-9\-_]*$/

  validates_presence_of :uid, :message => 'は必須です'
  validates_uniqueness_of :uid, :message => 'は既に登録されています'
  validates_length_of :uid, :minimum => UID_MIN_LENGTH, :message => "は%d文字以上で入力してください"
  validates_length_of :uid, :maximum => UID_MAX_LENGTH, :message => "は%d文字以内で入力してください"
  validates_format_of :uid, :message => 'は数字orアルファベットor記号で入力してください', :with => UID_FORMAT_REGEX

  def validate
    errors.add(:uid, "は#{CUSTOM_RITERAL[:login_account]}と異なる形式で入力してください") if uid_type == UID_TYPE[:nickname] && uid =~ USER_CODE_FORMAT_REGEX
  end

  class << self
    HUMANIZED_ATTRIBUTE_KEY_NAMES = {
      "uid" => "ニックネーム"
    }
    def human_attribute_name(attribute_key_name)
      HUMANIZED_ATTRIBUTE_KEY_NAMES[attribute_key_name] || super
    end
  end

  # uid入力チェック（ajaxのアクションから利用）
  def self.check_uid uid, code
    return "#{CUSTOM_RITERAL[:login_account]}と異なる形式で入力してください" if uid != code && uid =~ USER_CODE_FORMAT_REGEX
    return "#{UID_MIN_LENGTH}文字以上入力してください" if uid and uid.length < UID_MIN_LENGTH
    return "#{UID_MAX_LENGTH}文字以内で入力してください" if uid and uid.length > UID_MAX_LENGTH
    return "英数もしくは-(ハイフン)、_(アンダーバー)のみで入力してください" unless uid =~ UID_FORMAT_REGEX
    User.find_by_uid(uid) ? "既に同一のニックネームが登録されています" : "登録可能です"
  end
end
