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

Given /^メール機能を有効にする$/ do
  SkipEmbedded::InitialSettings['mail']['show_mail_function'] = true
end

Given /^お知らせ機能を有効にする$/ do
  SkipEmbedded::InitialSettings['notice_entry']['enable'] = true
end

Given /^Wiki機能を有効にする$/ do
  SkipEmbedded::InitialSettings['wiki']['use'] = true
end

Given /^質問の告知方法の既定値をメール送信にする機能を"([^\"]*)"にする$/ do |str|
  if str == '有効'
    SkipEmbedded::InitialSettings['mail']['default_send_mail_of_question'] = true
  else
    SkipEmbedded::InitialSettings['mail']['default_send_mail_of_question'] = false
  end
end

module SkipEmbedded
  class InitialSettings
    # テストの時のみ値の入れ替えを可能にしたいので。
    def self.[]=(key, val)
      instance.instance_variable_set(:@config, instance.instance_variable_get(:@config).dup)
      instance.instance_variable_get(:@config)[key] = val
    end
  end
end
