# SKIP（Social Knowledge & Innovation Platform）
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

describe Bookmark do
  fixtures :bookmarks, :bookmark_comments

  # 非公開コメントのみのブックマークは表示しない
  def test_find_visible
    bookmarks = Bookmark.find_visible(5)

    assert !( bookmarks.include? @a_private_bookmark )
    assert ( bookmarks.include? @a_public_bookmark )
    assert ( bookmarks.include? @a_mixed_bookmark )
  end

  # ブックマークされたURLが全公開可能か
  def test_url_is_public?
    # 全公開のエントリの場合 true
    assert @a_public_page_bookmark.url_is_public?
    # 全公開以外のエントリの場合 false
    assert !@a_private_page_bookmark.url_is_public?
    # 外部のURLの場合 true
    assert @a_bookmark.url_is_public?
  end
end
