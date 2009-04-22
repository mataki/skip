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

class AntennaController < ApplicationController

  verify :method => :post, :only => [ :add_symbol, :add_antenna_and_symbol, :ado_add_antenna_item ]

  def select_antenna
    antennas = Antenna.find_with_included session[:user_id], params[:symbol]
    render :layout => 'dialog', :partial => 'select_antenna',
           :locals => {:antennas => antennas,
                       :symbol => params[:symbol]}
  end

  def add_symbol
    redirect_to_with_deny_auth and return unless login_user_antenna?(params[:antenna_id])

    antenna_item = AntennaItem.new(:antenna_id => params[:antenna_id],
                                   :value_type => :symbol.to_s,
                                   :value => params[:symbol])
    if antenna_item.save
      render(:partial => 'selected_antenna')
    else
      antennas = Antenna.find_with_included session[:user_id], params[:symbol]
      render(:partial => 'select_antenna',
             :locals => { :antennas => antennas,
                          :symbol => params[:symbol],
                          :messages => antenna_item.errors.full_messages.join(",")})
    end
  end

  def add_antenna_and_symbol
    messages = ""

    unless params[:antenna][:name].empty?
      @antenna = Antenna.create(:user_id => session[:user_id], :name => params[:antenna][:name])
      if @antenna.errors.empty?
        params[:antenna_id] = @antenna.id
        add_symbol
      else
        @antenna.errors.each_full {  |msg| messages <<  msg }
      end
    else
      messages = "アンテナ名称は必須です"
    end

    unless messages.empty?
      antennas = Antenna.find_with_included session[:user_id], params[:symbol]
      render(:partial => 'select_antenna',
             :locals => {:antennas => antennas,
                         :symbol => params[:symbol],
                         :messages => messages})
    end
  end

  def ado_add_antenna_item
    unless login_user_antenna?(params[:antenna_id])
      render :text => _('不正なアンテナが指定されました。'), :status => :bad_request and return
    end
    unless item = Symbol.get_item_by_symbol(params[:symbol])
      render :text => _('存在しないオーナーが指定されました。'), :status => :bad_request and return
    end
    antenna_item = AntennaItem.new(:antenna_id => params[:antenna_id],
                                   :value_type => :symbol.to_s,
                                   :value => params[:symbol])
    if antenna_item.save
      render :partial => 'antenna_item', :locals => {:antenna_item => antenna_item, :antenna_id => antenna_item.antenna_id}
    else
      render :text => antenna_item.errors.full_messages, :status => :bad_request
    end
  end

  def login_user_antenna? antenna_id
    Antenna.find(antenna_id).user_id == session[:user_id]
  end
end
