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

class Feed::ApplicationController < ApplicationController
  layout false
  skip_before_filter :sso, :login_required, :prepare_session
  before_filter :login_required_with_access_feed

  def login_required_with_access_feed
    SkipEmbedded::InitialSettings['publicize_feeds_without_login'] || login_required_without_access_feed
  end
  alias_method_chain :login_required, :access_feed
end
