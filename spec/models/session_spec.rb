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

require File.dirname(__FILE__) + '/../spec_helper'

describe Session do
  #ここではfixtureは使わないことにする #fixtures :sessions

  def test_create_sso_sid
    #一度セッションを消す
    Session.destroy_all

    #一人目(Gomi)ログイン
    user_info_gomi = { 'code' => '300317', 'name' => 'Gomi', 'email' => 'hisae@tis.co.jp', 'section' => 'TC'}
    sid_gomi_1 = Session.create_sso_sid user_info_gomi, 'abc', Time.now + 1.month
    assert_equal Session.find_all_by_user_code(user_info_gomi['code']).size, 1

    #一人目が別のブラウザでログイン
    sid_gomi_2 = Session.create_sso_sid user_info_gomi, 'abc', Time.now + 1.month
    assert_equal Session.find_all_by_user_code(user_info_gomi['code']).size, 2
    assert sid_gomi_1 != sid_gomi_2

    #二人目(Nami)ログイン
    user_info_nami = { 'code' => '301375', 'name' => 'Nami', 'email' => 'namikawa@example.com', 'section' => 'TC'}
    sid_nami_1 = Session.create_sso_sid user_info_nami, 'abc', Time.now + 1.month
    assert_equal Session.find_all_by_user_code(user_info_nami['code']).size, 1

    #二人目(Nami)が別ブラウザでログイン
    sid_nami_2 = Session.create_sso_sid user_info_nami, 'abc', Time.now + 1.month
    assert_equal Session.find_all_by_user_code(user_info_nami['code']).size, 2
    assert sid_nami_1 != sid_nami_2

    #一人目が3つ目の別のブラウザでログイン
    sid_gomi_3 = Session.create_sso_sid user_info_gomi, 'abc', Time.now + 1.month
    assert_equal Session.find_all_by_user_code(user_info_gomi['code']).size, 3
    assert sid_gomi_1 != sid_gomi_3
    assert sid_gomi_2 != sid_gomi_3
  end
end
