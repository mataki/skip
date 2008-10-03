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

class StatisticsController < ApplicationController
  before_filter :setup_layout
  helper :calendar

  def index
    @date = Date.today
    if (params[:year] and params[:month] and params[:day])
      @date = Date.new(params[:year].to_i, params[:month].to_i, params[:day].to_i)
      @site_count = SiteCount.get_by_date(@date) || SiteCount.new
    else
      @site_count = SiteCount.find(:first, :order => "created_on desc") || SiteCount.new
    end
    flash[:notice] = _('対象データが見つかりません。') if @site_count.new_record?
    @item_count = get_site_count_hash_by_day @date
  end

  def load_calendar
    render :partial => "shared/calendar",
           :locals => { :sel_year => params[:year].to_i,
                        :sel_month => params[:month].to_i,
                        :sel_day => nil,
                        :item_count => get_site_count_hash_by_day(Date.new(params[:year].to_i, params[:month].to_i)),
                        :action => 'index'}
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
    date = Date.new(params[:year].to_i, params[:month].to_i)
    if params[:type] == "monthly"
      site_counts = SiteCount.find(:all,
                                   :conditions => ["DATE_FORMAT(created_on, '%Y-%m') = ?", date.strftime('%Y-%m')]) #"
      values = site_counts.map {|site_count| site_count[params[:category]] }
      max_value = values.max
      min_value = values.min
      render :partial => 'monthly_history',
             :locals => {:history_title => params[:desc],
                         :site_counts => site_counts,
                         :category => params[:category],
                         :date => date,
                         :max_value => max_value,
                         :min_value => min_value},
             :layout => false
    end
  end

private
  def setup_layout
    @main_menu = @title = "数字で見る#{ERB::Util.h(Admin::Setting.abbr_app_title)}"

    @tab_menu_source = [ [ @title, 'index' ] ]
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
