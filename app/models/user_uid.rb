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

class UserUid < ActiveRecord::Base
  belongs_to :user

  UID_TYPE = {
    :master => 'MASTER',
    :username => 'NICKNAME'
  }

  UID_MAX_LENGTH = 30
  UID_FORMAT_REGEX = /^[a-zA-Z0-9\-_\.]*$/

  N_('UserUid|Uid')

<<<<<<< HEAD:app/models/user_uid.rb
  named_scope :partial_match_uid, proc {|word|
    {:conditions => ["uid LIKE ?", SkipUtil.to_lqs(word)]}
  }

  validates_presence_of :uid
  validates_uniqueness_of :uid, :case_sensitive => false
  validates_length_of :uid, :within => SkipEmbedded::InitialSettings['user_code_minimum_length'].to_i..UID_MAX_LENGTH
  validates_format_of :uid, :with => UID_FORMAT_REGEX, :message => _('は数字、アルファベット及び次の記号[-(ハイフン)、_(アンダースコア)、.(ドット)]が利用可能です。その他の記号、半角空白などは使えません。')

  def validate
    errors.add(:uid, _('は%{login_account}と異なる形式で入力してください。') % {:login_account => Admin::Setting.login_account}) if uid_type == UID_TYPE[:username] && uid =~ user_code_format_regex
=======
  validates_presence_of :uid, :message => _('is mandatory.')
  validates_uniqueness_of :uid, :message => _('has already been registered.')
  validates_length_of :uid, :minimum => UID_MIN_LENGTH, :message => _("requires %d or more characters.")
  validates_length_of :uid, :maximum => UID_MAX_LENGTH, :message => _("accepts %d or less characters only.")
  validates_format_of :uid, :message => _('accepts numbers, alphapets and symbols.'), :with => UID_FORMAT_REGEX

  def validate
    errors.add(:uid, _("needs to be in different format from %s.") % Admin::Setting.login_account) if uid_type == UID_TYPE[:username] && uid =~ UID_CODE_REGEX
>>>>>>> for_i18n:app/models/user_uid.rb
  end

  def self.validation_error_message uid
    u = new(:uid => uid, :uid_type => UID_TYPE[:username])
<<<<<<< HEAD:app/models/user_uid.rb
    u.valid? ? nil : u.errors.full_messages.join(',')
  end

#  private
  def user_code_format_regex
    Regexp.new(SkipEmbedded::InitialSettings['user_code_format_regex'])
=======
    u.valid? ? _('Usable.') : u.errors.full_messages.join(',')
>>>>>>> for_i18n:app/models/user_uid.rb
  end
end
