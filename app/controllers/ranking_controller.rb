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

class RankingController < ApplicationController
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

  # GET /rankings/:content_type/:year/:month
  def index
    # TODO 要リファクタ(route.rb)
    if params[:content_type].blank?
      return head(:bad_request)
    else
      if params[:year].blank?
        @rankings = Ranking.total(params[:content_type])
        if @rankings.empty?
          head(:not_found)
        end
      else
        if params[:month].blank?
          head(:bad_request)
        else
          begin
            Time.local(params[:year], params[:month])
            @rankings = Ranking.monthly(params[:content_type], params[:year], params[:month])
            if @rankings.empty?
              head(:not_found)
            end
          rescue => e
            head(:bad_request)
          end
        end
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
      render :layout => 'layout'
    rescue => e
      head(:bad_request)
    end
  end
end
