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

require File.dirname(__FILE__) + '/../spec_helper'
require 'batch_cleanup_session'

describe CleanupSession do
  fixtures :sessions

  def test_execute
    #fixture読み込み確認
    assert_equal Session.find(:all).size, 4
    CleanupSession.execute
    #fixtureの中で2つは消えて、2つは残る。残るのはexpire_dateが現在より大きいもの
    exist_session = Session.find(:all)
    assert_equal exist_session.size, 2
    assert exist_session.first.expire_date > Time.now
    assert exist_session.last.expire_date > Time.now
  end
end
