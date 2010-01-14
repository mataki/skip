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

require 'kconv'
class SkipUtil
  GetText.N_("Sun")
  GetText.N_("Mon")
  GetText.N_("Tue")
  GetText.N_("Wed")
  GetText.N_("Thu")
  GetText.N_("Fri")
  GetText.N_("Sat")
  
  WDAYS = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]

  def self.split_symbol symbol
    symbol_type = symbol.split(":").first
    symbol_id   = symbol.split(":").last
    return symbol_type, symbol_id
  end

  def self.to_like_query_string string
    '%' + string.to_s + '%'
  end

  def self.to_lqs string
    self.to_like_query_string string
  end

  def self.jstrip string
    string.sub(/\A[\s　]+/, "").sub(/[\s　]+\z/, "")
  end

  # CSV出力用のための変換処理(引数：CSVの1行分のカラムの値の配列)
  def self.get_a_row_for_csv array
    array.map {|col| NKF.nkf('-sZ', col) }
  end

  def self.full_error_messages array
    array.is_a?(Array) ? array.map{ |item| item.errors.full_messages unless item.valid? }.flatten.compact : []
  end

  def self.toutf8_without_ascii_encoding string
    if string
      Kconv.guess(string) == Kconv::ASCII ? string : string.toutf8
    end
  end
end
