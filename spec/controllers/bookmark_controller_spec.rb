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

describe BookmarkController do
  fixtures :bookmarks, :users, :user_uids

  def setup
    @controller = BookmarkController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  def test_update
    @request.session[:user_code] = "100001"
    # 必須項目の新規作成の場合
    post :update, {:bookmark => {:url => SkipFaker.url, :title => SkipFaker.rand_char},
                   :bookmark_comment => {:tags => '', :public => true, :comment => SkipFaker.rand_char },
                   :layout => 'dialog' }
    assert_response :ok

    # 全項目の新規作成の場合
    post :update, {:bookmark => {:url => SkipFaker.url, :title => SkipFaker.rand_char},
                   :bookmark_comment => {:tags => SkipFaker.tag, :public => true, :comment => SkipFaker.rand_char},
                   :layout => 'dialog' }
    assert_response :ok

    # 必須項目の更新の場合
    post :update, {:bookmark => {:url => @a_bookmark.url, :title => SkipFaker.rand_char},
                   :bookmark_comment => {:public => true}, :layout => 'dialog' }
    assert_response :ok

    # 全項目の更新の場合
    post :update, {:bookmark => {:url => @a_bookmark.url, :title => SkipFaker.rand_char},
                   :bookmark_comment => {:tags => SkipFaker.tag, :public => true, :comment => SkipFaker.rand_char},
                   :layout => 'dialog' }
    assert_response :ok
  end
end
