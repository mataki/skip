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

class UserUid < ActiveRecord::Base
  belongs_to :user

  UID_TYPE = {
    :master => 'MASTER',
    :username => 'NICKNAME'
  }

  UID_MAX_LENGTH = 30
  UID_FORMAT_REGEX = /^[a-zA-Z0-9\-_\.]*$/

  N_('UserUid|Uid')

  named_scope :partial_match_uid, proc {|word|
    {:conditions => ["uid LIKE ?", SkipUtil.to_lqs(word)]}
  }

  validates_presence_of :uid
  validates_uniqueness_of :uid, :case_sensitive => false
  validates_length_of :uid, :within => SkipEmbedded::InitialSettings['user_code_minimum_length'].to_i..UID_MAX_LENGTH
  validates_format_of :uid, :with => UID_FORMAT_REGEX, :message => _("accepts numbers, alphapets, hiphens(\"-\"), underscores(\"_\") and dot(\".\").")

  def validate
    errors.add(:uid, _("needs to be in different format from %s.") % Admin::Setting.login_account) if uid_type == UID_TYPE[:username] && uid =~ user_code_format_regex
  end

  def self.validation_error_message uid
    u = new(:uid => uid, :uid_type => UID_TYPE[:username])
    u.valid? ? nil : u.errors.full_messages.join(',')
  end

#  private
  def user_code_format_regex
    Regexp.new(SkipEmbedded::InitialSettings['user_code_format_regex'])
  end
end
