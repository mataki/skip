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

class StatisticsController < ApplicationController
  before_filter :setup_layout

  def index
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
                        :item_count => get_site_count_hash_by_day(Date.new(params[:year].to_i, params[:month].to_i)) }
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

  private
  def setup_layout
    @main_menu = @title = _('Site Information')
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

end
