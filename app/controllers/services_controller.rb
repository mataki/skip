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

class ServicesController < ActionController::Base
  session :off
  skip_before_filter :sso

  include ForServicesModule
  before_filter :check_secret_key, :except => [:search_conditions]
  after_filter :change_charset

  # ユーザに関連する情報を取得する
  def user_info
    result = {}
    if user = User.find_by_uid(params[:user_code])
      group_hash = {}
      user.group_participations.find(:all, :conditions => ["waiting = ?", false]).each do |p|
        group_hash[p.group.gid] = p.group.name
      end
      result = { :user_uid => user.uid, :group_symbols => group_hash }
    else
      result = { :error => "#{Admin::Setting.abbr_app_title}にユーザ情報が登録されていません。" }
    end
    render :text => result.to_json
  end

  def search_conditions
    @contents = [ { :type => "",            :icon => 'asterisk_orange', :name => "すべて" },
                  { :type => "entry",       :icon => 'report',          :name => "ブログ/BBS" },
                  { :type => "bookmark",    :icon => 'tag_blue',        :name => "ブックマーク" },
                  { :type => "user",        :icon => 'user_suit',       :name => "ユーザ" },
                  { :type => "group",       :icon => 'group',           :name => "グループ" },
                  { :type => "share_file", :icon => 'disk_multiple',   :name => "ファイル" } ]
  end

  def new_users
    render :text => diff_users('new',params[:from_date])
  end

  def retired_users
    render :text => diff_users('retired',params[:from_date])
  end

private
  def diff_users new_or_retired, from_date
    conditions = new_or_retired == 'new' ? ["status = ?", 'ACTIVE'] : ["status = ?", 'RETIRED']
    if from_date
      conditions[0] += " and updated_on > ?"
      conditions << from_date
    end
    users = User.find(:all, :conditions => conditions)
    users = users.map!{ |user| user.code }.join(',') || ""
    return { :users => users }.to_json
  end

  # 文字コードの指定が ?charset=euc-jp と指定していたら変換する
  def change_charset
    charset = 'UTF-8'
    charset, response.body = 'EUC-JP', NKF::nkf('-e', response.body) if params[:charset] == 'euc-jp'
    headers["Content-Type"] = "application/x-javascript; charset=#{charset}"
  end
end
