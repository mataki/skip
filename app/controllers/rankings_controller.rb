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

class RankingsController < ApplicationController
  before_filter :setup_layout
  layout false
# TODO 外部からのランキング取り込み機能は一旦ペンディングなのでコメントアウト
#  def update
#    new_ranking = Ranking.new params[:ranking]
#    exisiting_ranking = Ranking.find_by_url_and_extracted_on_and_contents_type(new_ranking.url, new_ranking.extracted_on, new_ranking.contents_type)
#    if exisiting_ranking.empty?
#      if new_ranking.save
#        head :created
#      else
#        head :bad_request
#      end
#    else
#      if exisiting_ranking.first.add_amount(new_ranking.amount)
#        head :ok
#      else
#        head :bad_request
#      end
#    end
#  end
  def index
    today = Date.today
    redirect_to monthly_path(:year => today.year, :month => today.month)
  end

  # GET /ranking_data/:content_type/:year/:month
  def data
    if params[:content_type].blank?
      return head(:bad_request)
    end

    if params[:year].blank?
      @rankings = Ranking.total(params[:content_type])
      return head(:not_found) if @rankings.empty?
    else
      return head(:bad_request) if params[:month].blank?
      begin
        Time.local(params[:year], params[:month])
        @rankings = Ranking.monthly(params[:content_type], params[:year], params[:month])
        return head(:not_found) if @rankings.empty?
      rescue => e
        return head(:bad_request)
      end
    end
  end

  def all
    render :layout => 'layout'
  end

  def monthly
    today = Date.today
    year = params[:year].blank? ? today.year : params[:year]
    month = params[:month].blank? ? today.month : params[:month]
    begin
      time = Time.local(year, month)
      @year = time.year
      @month = time.month
      @dates = (0..23).map { |i| today.ago(i.month).strftime('%Y-%m') }
      render :layout => 'layout'
    rescue => e
      head(:bad_request)
    end
  end

  private
  def setup_layout
    @main_menu = @title = 'ランキング'

    @tab_menu_source = [ ['月別ランキング', 'monthly'],
                         ['総合ランキング', 'all'] ]
  end
end
