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

class RankingsController < ApplicationController
  before_filter :setup_layout
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
    yesterday = Date.yesterday
    redirect_to monthly_path(:year => yesterday.year, :month => yesterday.month)
  end

  # GET /ranking_data/:content_type/:year/:month
  def data
    if params[:content_type].blank?
      return head(:bad_request)
    end

    if params[:year].blank?
      @rankings = Ranking.total(params[:content_type])
      return render(:text => '', :status => :not_found) if @rankings.empty?
    else
      return render(:text => _('Invalid request.'), :status => :bad_request) if params[:month].blank?
      begin
        year, month = validate_time(params[:year], params[:month])
        @rankings = Ranking.monthly(params[:content_type], year, month)
        return render(:text => '', :status => :not_found) if @rankings.empty?
      rescue => e
        return render(:text => _('Invalid request.'), :status => :bad_request)
      end
    end
    render :layout => false
  end

  def all
    @dates = Ranking.extracted_dates
  end

  def monthly
    yesterday = Date.yesterday
    year = params[:year].blank? ? yesterday.year : params[:year]
    month = params[:month].blank? ? yesterday.month : params[:month]
    begin
      year, month = validate_time(year, month)
      @year = year
      @month = month
      @dates = Ranking.extracted_dates
    rescue => e
      flash.now[:error] = _('Invalid parameter(s) detected.')
      e.backtrace.each { |message| logger.error message }
      render :text => '', :status => :bad_request
    end
  end

  def bookmark
    # parse出来ないケースで例外を起こして現在時刻を設定するため
    @target_date = Time.parse(params[:target_date], 0) rescue Time.now

    popular_bookmarks = PopularBookmark.scoped(
      :conditions => ["date = ?", @target_date],
      :order =>'count DESC' ,
      :include => [:bookmark]
    ).all

    @bookmarks = []
    unless popular_bookmarks.empty?
      popular_bookmarks.each do |popular_bookmark|
        popular_bookmark.bookmark.bookmark_comments.each do |comment|
          if comment.public
            @bookmarks << popular_bookmark.bookmark
            break
          end
        end
      end
      @last_updated = popular_bookmarks.first.created_on.strftime(_("%B %d %Y"))
    else
      flash.now[:notice] = _('No matched bookmark.')
    end
  end

  private
  def setup_layout
    @main_menu = @title = _('Rankings')

# 一旦、非表示にし、機能は残しておく
#    @tab_menu_source = [ {:label => _('Monthly Rankings'), :options => {:action => 'monthly'}},
#                         {:label => _('Popular Bookmarks'), :options => {:action => 'bookmark'}} ]
  end

  def validate_time(year, month)
    time = Time.local(year, month)
    max_year = 2038
    min_year = 2000
    year = year.to_i
    raise ArgumentError, "year must be < #{max_year}." if year >= max_year
    raise ArgumentError, "year must be >= #{min_year}." if year < min_year
    [time.year, time.month]
  end
end
