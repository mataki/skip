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

  def statistics
    @date = Date.today
    if (params[:year] and params[:month] and params[:day])
      @date = Date.new(params[:year].to_i, params[:month].to_i, params[:day].to_i)
      @site_count = SiteCount.get_by_date(@date) || SiteCount.new
    else
      @site_count = SiteCount.find(:first, :order => "created_on desc") || SiteCount.new
    end
    flash[:notice] = _('Data not found.') if @site_count.new_record?
    @item_count = get_site_count_hash_by_day @date
  end

  def load_calendar
    render :partial => "shared/calendar",
           :locals => { :sel_year => params[:year].to_i,
                        :sel_month => params[:month].to_i,
                        :sel_day => nil,
                        :item_count => get_site_count_hash_by_day(Date.new(params[:year].to_i, params[:month].to_i)),
                        :action => 'statistics'}
  end

  # ajax_action
  def ado_current_statistics
    date = Date.new(params[:year].to_i, params[:month].to_i, params[:day].to_i)
    site_count = SiteCount.find(:first,
                                :conditions => ["DATE_FORMAT(created_on, '%Y-%m-%d') = ?", date.strftime('%Y-%m-%d')]) || SiteCount.new #"
    render :partial => "current_statistics", :locals => { :site_count => site_count }
  end

  # ajax_action
  def ado_statistics_history
    unless SiteCount::STATISTICS_KEYS.include? params[:category]
      return head(:bad_request)
    end
    # parse出来ないケースで例外を起こして現在時刻を設定するため
    date = Time.parse("#{params[:year]}/#{params[:month]}", 0) rescue Time.now
    site_counts = SiteCount.all :conditions => ["DATE_FORMAT(created_on, '%Y-%m') = ?", date.strftime('%Y-%m')]
    values = site_counts.map { |site_count| site_count[params[:category]] }
    render :partial => 'monthly_history',
           :locals => { :site_counts => site_counts,
                        :category => params[:category],
                        :date => date,
                        :max_value => values.max,
                        :min_value => values.min },
           :layout => false
  end

  def bookmark
    # parse出来ないケースで例外を起こして現在時刻を設定するため
    @target_date = Time.parse(params[:target_date], 0) rescue Time.now

    popular_bookmarks = PopularBookmark.find(:all,
                                             :conditions => ["date = ?", @target_date],
                                             :order =>'count DESC' ,
                                             :include => [:bookmark])
    @bookmarks = []
    if popular_bookmarks && popular_bookmarks.size > 0
      popular_bookmarks.each do |popular_bookmark|
        popular_bookmark.bookmark.bookmark_comments.each do |comment|
          if comment.public
            @bookmarks << popular_bookmark.bookmark
            break
          end
        end
      end
      @last_updated = popular_bookmarks.first.created_on.strftime("%Y/%m/%d %H:%M")
    else
      flash.now[:notice] = _('No matched bookmark.')
    end
  end

  private
  def setup_layout
    @main_menu = @title = _('Rankings')

    @tab_menu_source = [ {:label => _('Monthly Rankings'), :options => {:action => 'monthly'}},
                         {:label => _('Overall Rankings'), :options => {:action => 'all'}},
                         {:label => _('Popular Bookmarks'), :options => {:action => 'bookmark'}},
                         {:label => _('Site Information'), :options => {:action => 'statistics'}} ]
  end

  def get_site_count_hash_by_day date
    site_counts = SiteCount.find(:all,
                                 :conditions => ["DATE_FORMAT(created_on, '%Y-%m') = ?", date.strftime('%Y-%m')]) #"
    result = {}
    site_counts.each do |site_count|
      result[site_count.created_on.day] = 1
    end
    return result
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
