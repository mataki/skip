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

class DevelopController < ApplicationController
  before_filter :setup_layout
  helper :calendar

  verify :method => :post, :only => [ :create_message ],
         :redirect_to => { :action => :index }

  def index
    unless @group = Group.find_by_gid(Admin::Setting.develop_team_gid)
      flash[:warning] = "関係者用グループが存在していません"
      redirect_to :controller => "mypage"
      return
    end

    @users = @group.participation_users :limit => 10,
                                        :order => "group_participations.updated_on DESC",
                                        :waiting => false

    find_params = BoardEntry.make_conditions(login_user_symbols, {:symbol => @group.symbol, :category => 'リリースノート'})
    @release_messages = BoardEntry.find(:all,
                                        :limit => 5,
                                        :conditions=> find_params[:conditions],
                                        :order=>"last_updated DESC",
                                        :include => find_params[:include] | [ :state, :board_entry_comments ])

    find_params = BoardEntry.make_conditions(login_user_symbols, {:symbol => @group.symbol, :category => 'お知らせ'})
    @info_messages = BoardEntry.find(:all,
                                     :limit => 5,
                                     :conditions=>find_params[:conditions],
                                     :order=>"last_updated DESC",
                                     :include => find_params[:include] | [ :state, :board_entry_comments ])

    find_params = BoardEntry.make_conditions(login_user_symbols, {:symbol => @group.symbol, :category => 'ヒント'})
    @hint_messages = BoardEntry.find(:all,
                                     :limit => 5,
                                     :conditions=> find_params[:conditions],
                                     :order=>"last_updated DESC",
                                     :include => find_params[:include] | [ :state, :board_entry_comments ])

    find_params = BoardEntry.make_conditions(login_user_symbols, {:symbol => @group.symbol, :category => '運用環境'})
    @environment_message = BoardEntry.find(:first,
                                     :conditions=> find_params[:conditions],
                                     :include => find_params[:include],
                                     :order=>"last_updated DESC")

    @entry ||= BoardEntry.new(:category => "不具合")
  end

  def statistics
    @date = Date.today
    if (params[:year] and params[:month] and params[:day])
      @date = Date.new(params[:year].to_i, params[:month].to_i, params[:day].to_i)
      @site_count = SiteCount.get_by_date(@date) || SiteCount.new
    else
      @site_count = SiteCount.find(:first, :order => "created_on desc") || SiteCount.new
    end
    flash[:notice] = '対象データが見つかりません。' if @site_count.new_record?
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

  # 不具合・要望受付処理
  # post_action
  def create_message
    if params[:entry][:title] == "" and params[:entry][:contents] == ""
      flash[:warning] = "件名と内容を入力してください"
      redirect_to :action => 'index'
      return
    elsif params[:entry][:title] == "" or params[:entry][:contents] == ""
      @entry = BoardEntry.new(:title => params[:entry][:title], :contents => params[:entry][:contents], :category => params[:entry][:category])
      flash[:warning] = "投稿には、件名と内容の双方が必須です"
      index
      render :action => 'index'
      return
    end

    develop_temp_symbol = "gid:" + Admin::Setting.develop_team_gid
    entry_params = { }
    entry_params[:non_auto] = true
    entry_params[:title] = params[:entry][:title]
    entry_params[:message] = params[:entry][:contents]
    entry_params[:tags] = params[:entry][:category]
    entry_params[:user_symbol] = session[:user_symbol]
    entry_params[:user_id] = session[:user_id]
    entry_params[:entry_type] = BoardEntry::GROUP_BBS
    entry_params[:owner_symbol] = develop_temp_symbol

    if params[:entry][:category] == "問合せ,連絡"
      entry_params[:publication_type] = 'private'
      entry_params[:publication_symbols] = [develop_temp_symbol, session[:user_symbol]]
    else
      entry_params[:publication_type] = 'public'
      entry_params[:publication_symbols] = [Symbol::SYSTEM_ALL_USER]
    end
    @entry = BoardEntry.create_entry(entry_params)
    if @entry.errors.full_messages == []
      flash[:notice] = "あなたの#{@entry.category}投稿を受け付けました"
      redirect_to :action => 'index'
      return
    end
    index
    render :action => 'index'
  end

private
  def setup_layout
    @main_menu = @title = 'サイト情報'

    @tab_menu_source = [ ['リリースノート', 'index'],
                         ["数字で見る#{ERB::Util.h(Admin::Setting.abbr_app_title)}", 'statistics' ] ]
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
