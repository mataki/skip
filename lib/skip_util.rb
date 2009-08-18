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

require 'kconv'
class SkipUtil
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

  ######################################################################
  # 画像表示
  # view_str:文字列
  # proc　イメージのURLを生成できるブロック(ファイル名を引数に取るもの)
  def self.images_parse view_str, proc

    regex_type = /\{\{.+?\}\}/ # {{***}}とマッチする正規表現
    image_size = [0,0] # デフォルトサイズ
    image_name = ""
    file_count = 0

    while image_tag = view_str.match(regex_type)
      image_size = [0,0] # デフォルトサイズ

      # カンマ２つでサイズが指定してある場合
      if  image_tag.to_s.scan(",").size == 2
        params = image_tag.to_s[2..-3].split(",")
        image_name = params[0]
        image_size = [params[1].to_i, params[2].to_i]
      else
        image_name = image_tag.to_s[2..-3]
      end
      image_name.strip!

      #イメージのURLを生成できるブロックを呼び出す
      image_url = proc.call(image_name)
      if File.extname(image_name).downcase == ".flv"
        image_size[0] = 240 if image_size.first == 0
        image_size[1]  = 240 if image_size.last == 0
        image_link = "<p id='player#{file_count}'><a href='http://www.macromedia.com/go/getflashplayer'>Get the Flash Player</a> to see this player.</p>"
        image_link << '<script type="text/javascript">'
        image_link << "var F#{file_count} = { movie:'/flvplayer.swf',"
        image_link << "width:'#{image_size.first}'," if image_size.first > 0
        image_link << "height:'#{image_size.last}'," if image_size.last > 0
        image_link << "majorversion:'7',build:'0',bgcolor:'#FFFFFF',"
        image_link << "flashvars:'file=#{image_url}&showdigits=true&autostart=false&showfsbutton=true' };"
        image_link << "UFO.create(F#{file_count}, 'player#{file_count}');"
        image_link << '</script>'
        file_count += 1
      elsif File.extname(image_name).downcase == ".swf"
        image_size[0] = 240 if image_size.first == 0
        image_size[1] = (image_size[0] * 0.75) if image_size.last == 0
        image_link = "<div style='width: #{image_size.first}px;'>"
        image_link << "<object id='flash#{file_count}' data='#{image_url}' width='#{image_size.first}' height='#{image_size.last}'"
        image_link << "type='application/x-shockwave-flash'>"
        image_link << "<param name='movie' value='#{image_url}' />"
        image_link << "</object>"
        image_link << "<div style='text-align: center;'>"
        image_link << "<a href='javascript: $j(\"#flash#{file_count}\")[0].Play();'>" + _("[Play/Next]")+ "</a>"
        image_link << "<a href='javascript: $j(\"#flash#{file_count}\")[0].Rewind();'>" + _("[Rewind]") + "</a>"
        image_link << "</div></div>"
      else
        image_link = "<a href='#{image_url}' class=\"nyroModal zoomable\" ><img src='#{image_url}' "
        image_link << "width='#{image_size.first}' " if image_size.first > 0
        image_link << "height='#{image_size.last}' " if image_size.last > 0
        image_link << " /></a>"
      end

      view_str = view_str.sub(regex_type, image_link)
    end
    return view_str
  end
end
