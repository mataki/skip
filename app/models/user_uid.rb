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

class UserUid < ActiveRecord::Base
  belongs_to :user

  UID_TYPE = {
    :master => 'MASTER',
    :username => 'NICKNAME'
  }

  UID_MIN_LENGTH = 4
  UID_MAX_LENGTH = 30
  UID_FORMAT_REGEX = /^[a-zA-Z0-9\-_]*$/
  UID_CODE_REGEX = Regexp.new(INITIAL_SETTINGS['user_code_format_regex'])

  N_('UserUid|Uid')

  validates_presence_of :uid, :message => 'は必須です'
  validates_uniqueness_of :uid, :message => 'は既に登録されています'
  validates_length_of :uid, :minimum => UID_MIN_LENGTH, :message => "は%d文字以上で入力してください"
  validates_length_of :uid, :maximum => UID_MAX_LENGTH, :message => "は%d文字以内で入力してください"
  validates_format_of :uid, :message => 'は数字orアルファベットor記号で入力してください', :with => UID_FORMAT_REGEX

  def validate
    errors.add(:uid, "は#{Admin::Setting.login_account}と異なる形式で入力してください") if uid_type == UID_TYPE[:username] && uid =~ UID_CODE_REGEX
  end

  def self.validation_error_message uid
    u = new(:uid => uid, :uid_type => UID_TYPE[:username])
    u.valid? ? nil : u.errors.full_messages.join(',')
  end
end
