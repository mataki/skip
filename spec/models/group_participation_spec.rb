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

require File.dirname(__FILE__) + '/../spec_helper'

describe GroupParticipation, '#group' do
  before do
    user = create_user
    @group = create_group
    @group_participation = GroupParticipation.create!(:user_id => user.id, :group_id => @group.id)
  end
  it '一件のグループが取得できること' do
    @group_participation.group.should_not be_nil
  end
  describe 'グループを論理削除された場合' do
    before do
      @group.logical_destroy
    end
    it 'グループが取得できないこと' do
      @group_participation.group.should be_nil
    end
  end
end
