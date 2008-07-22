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

module RankingsHelper

  def summary_date_html summary_date, options ={}

    output = ""
    summary_format = "%m/%d"
    summary_format << " %H:%M" if this_month? summary_date
    summary_span = ""
    if options[:total_ranking_flg]
      summary_span << "#{CUSTOM_RITERAL[:abbr_app_title]}オープンから #{summary_date.strftime(summary_format)}"
    else
      summary_span << "#{summary_date.strftime('%Y/%m')}/01～#{summary_date.strftime(summary_format)}"
    end

    output << "<div>"
    output << "<span class='summary_span'>#{summary_span}</span> のランキング"
    output << "</div>"
  end

  def ranking_table(options={})
    options.assert_valid_keys [:rankings, :title, :unit, :exist_entry_title]

    img_star = icon_tag("star")
    col_span = options[:exist_entry_title] ? 4 : 3

    output = ""
    output << "<th class='title' colspan='#{col_span}'>#{img_star} #{options[:title]}#{img_star}</th>"
    output << "<tr><th>"
    if options[:exist_entry_title]
      output << "<th>タイトル</th>"
    end
    output << "</th><th>ユーザ名</th><th>#{options[:unit]}</th></tr>"

    rank = 0
    same_rank_cnt = 0
    old_rank_point = 0

    options[:rankings].each do |ranking|
      # 同順ランクを考慮
      if old_rank_point != ranking.point
        rank += same_rank_cnt + 1
        same_rank_cnt = 0
      else
        same_rank_cnt += 1
      end
      old_rank_point = ranking.point

      output << "<tr><td class='rank'>#{rank}</td>"
      if options[:exist_entry_title]
        output << "<td class='link_text'>"
        output << link_to_board_entry(ranking)
        output << "</td>"
      end
      output << "<td class='user_name'>"
      if options[:exist_entry_title]
        if @entry_info_from_board_entry_id.key?(ranking.link_id)
          output << user_link_to(@entry_info_from_board_entry_id[ranking.link_id].user)
        end
      else
        output << user_link_to(@user_from_user_id[ranking.link_id])
      end
      output << "</td>"
      output << "<td class='point'>#{ranking.point}</td></tr>"

    end

    return output
  end

  def generate_link_action current_month_rankings
    link_hash = {}
    current_month_rankings.each do |daily_ranking|
      hash_key = daily_ranking.created_on.strftime("%Y-%m-%d")
      link_hash.store(hash_key,
                      dummy_link_to(daily_ranking.created_on.day.to_s, :class => "daily_ranking_link", :id => hash_key))
    end
    return link_hash
  end

  def generate_monthly_ranking_options monthly_rankings
    options_hash = {}
    monthly_rankings.each { |ranking| options_hash.store(ranking.created_on.strftime("%Y年%m月　"), ranking.created_on.strftime("%Y-%m")) }
    return options_hash.sort_by{ |key, value| key }.reverse
  end

private

  def link_to_board_entry(ranking)
    entry = @entry_info_from_board_entry_id[ranking.link_id]
    unless entry
      "削除されたか閲覧制限が設定されています"
    else
      entry_link_to entry
    end
  end

  def this_month? month
    month.year == Date.today.year and month.month == Date.today.month
  end
end
