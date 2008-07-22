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

module Assistant

  class Calendar #カレンダークラス作成
  WeekName = [ '日', '月', '火', '水', '木', '金', '土', ]
  WeekColor = [
  '#ff0000', #Sun
  '#000000', #Mon
  '#000000', #Tue
  '#000000', #Wed
  '#000000', #Thu
  '#000000', #Fri
  '#0000ff', #Sat
  ]
  TodayColor = '#ffff00'
  LinkColor = 'lightblue'

  def initialize(year=Time.now.year, month=Time.now.month)
    @year = year.to_i
    @month = month.to_i
    @wday = []
    @daydata = []

    raise "Month Error" if (@month < 1) || (12 < @month)
    raise "Year Error" if (@year < 1) || (2037 < @year)

    nowday = Time.local(Time.now.year, Time.now.month, Time.now.day, 0, 0, 0)

    (1..31).each do |day|
      itsday = Time.local(@year, @month, day, 0, 0, 0)

      @daydata[day] = 'today' if nowday == itsday

      if day > 28 && itsday.month != @month
        @wday[day] = nil
      else
        @wday[day] = itsday.wday
      end
    end
  end

  # link_action -> { "yyyy-mm-dd" => "link_to ...", ... }
  def html_print link_action
    print_data = '<table class="calendar_table" border="1" cellspacing="0" cellpadding="0">'
    print_data += "<tr>"
    (0 .. WeekName.length - 1).each do |i|
      print_data += "<th><font color='#{WeekColor[i]}'>#{WeekName[i]}</font></th>"
    end
    print_data += "</tr>"

    (1 .. @wday.length).each do |day|
      break unless @wday[day]

      if day == 1
        print_data += "<td></td>" * @wday[day]
      elsif @wday[day] == 0
        print_data += "<tr>"
      end

      hash_key = sprintf("%4d", @year) + "-" + sprintf("%02d", @month) + "-" + sprintf("%02d", day) # YYYY-MM-DD
      link_str = link_action[hash_key] ? link_action[hash_key] : day

      print_data << "<td align='right'"

      if @daydata[day] == 'today'
        print_data << " bgcolor='#{TodayColor}'"
      elsif link_action[hash_key]
        print_data << " bgcolor='#{LinkColor}'"
      end
      print_data << "><font color='#{ WeekColor[@wday[day]]}'>#{link_str}</font></td>"

      if @wday[day] == 6
        print_data << "</tr>"
      end
    end
    print_data << "</table>"
  end
end

end
