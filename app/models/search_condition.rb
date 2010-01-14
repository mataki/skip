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

# 検索時に使う検索条件クラス（親クラス）
class SearchCondition
  include GetText
  bindtextdomain 'skip'

  def SearchCondition.create_by_params params
    condition = self.new
    if params[:condition]
      condition.assign params[:condition]

      params[:condition].each_key do |key|
        params["condition[" + key.to_s + "]"] = params[:condition][key]
      end
      params.delete(:condition)
    end
    condition
  end
end
