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

class AppliedEmail < ActiveRecord::Base
  validates_presence_of :email, :message =>'は必須です'
  validates_length_of :email, :maximum=>50, :message =>'は50桁以内で入力してください'
  validates_format_of :email, :message =>'は正しい形式で登録してください', :with => /^([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})$/

  class << self
    HUMANIZED_ATTRIBUTE_KEY_NAMES = {
      "email" => "メールアドレス",
    }
    def human_attribute_name(attribute_key_name)
      HUMANIZED_ATTRIBUTE_KEY_NAMES[attribute_key_name] || super
    end
  end

  def before_save
    source = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"
    self.onetime_code = ""
    50.times {|i| self.onetime_code << source[rand(source.size)] }
  end

end
