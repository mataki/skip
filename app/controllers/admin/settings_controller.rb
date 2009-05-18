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

# config/settings.ymlの内容をいくつかのビューにわけて表示/編集するコントローラ
# 具体的には全体設定、文言設定、メール関連設定、フィード設定、その他設定の各タブの
# 表示/更新を行う。
class Admin::SettingsController < Admin::ApplicationController
  N_('Admin::SettingsController|literal')
  N_('Admin::SettingsController|mail')
  N_('Admin::SettingsController|feed')
  N_('Admin::SettingsController|main')
  N_('Admin::SettingsController|security')

  helper_method :current_setting

  def index
    @topics = [[_("#{self.class.name}|#{params[:tab]}")]]
    @current_setting_hash = {}
    if params[:tab].blank?
      redirect_to admin_settings_path(:tab => :literal)
    end

    if params[:tab] == 'main'
      @system_infos = []
      @system_infos << {
        :name => _("共有ファイル関連"),
        :settings => [{ :label => _("現在の利用容量"),
                        :help => _("システム全体の最大許可容量に対して現在使用中の共有ファイルの容量です。"),
                        :value => "#{ValidationsFile::FileSizeCounter.per_system/1.megabyte} / #{SkipEmbedded::InitialSettings['max_share_file_size_of_system']/1.megabyte} (MB)"
                      },
                      setting_of('max_share_file_size_of_system', "#{SkipEmbedded::InitialSettings['max_share_file_size_of_system'].to_i/1.megabyte}(MB)"),
                      setting_of('max_share_file_size_per_owner', "#{SkipEmbedded::InitialSettings['max_share_file_size_per_owner'].to_i/1.megabyte}(MB)"),
                      setting_of('max_share_file_size', "#{SkipEmbedded::InitialSettings['max_share_file_size'].to_i/1.megabyte}(MB)")
                     ]
      }
      @system_infos << {
        :name => _("アカウント関連"),
        :settings => [setting_of('login_mode'),
                      login_mode?(:fixed_rp) ? setting_of('fixed_op_url', SkipEmbedded::InitialSettings['fixed_op_url'] || "利用しない") : nil,
                      setting_of('usercode_dips_setting'),
                      setting_of('password_edit_setting'),
                      setting_of('username_use_setting'),
                      setting_of('user_code_format_regex', SkipEmbedded::InitialSettings['user_code_format_regex'] || "利用しない"),
                      setting_of('user_code_minimum_length', SkipEmbedded::InitialSettings['user_code_minimum_length'])
                     ]
      }
      @system_infos << {
        :name => _("機能に関する設定"),
        :settings => [setting_of('ssl_setting'),
                      setting_of('full_text_search_setting'),
                      setting_of('proxy_url', SkipEmbedded::InitialSettings['proxy_url'] || "利用しない")
                     ]
      }
      @system_infos << {
        :name => _("システム運用について"),
        :settings => [setting_of('administrator_addr', SkipEmbedded::InitialSettings['administrator_addr'] || "指定なし")
                     ]
      }
    end
  end

  def update_all
    @current_setting_hash = params[:settings] || {}
    objects = @current_setting_hash.dup.symbolize_keys
    settings = []
    Admin::Setting.transaction do
      settings = objects.map do |name, value|
        # remove blank values in array settings
        value.delete_if {|v| v.blank? } if value.is_a?(Array)
        if [:mypage_feed_settings].include? name
          value = {} if value.blank?
          value = value.values.delete_if { |item| (item.class == String) ? item.blank? : has_empty_value?(item.values) }
        end
        # Admin::Setting[name] = value と評価すると value の値がmapに収納されてしまうので
        Admin::Setting.[]=(name,value)
      end
      @error_messages = Admin::Setting.error_messages(settings)
      raise ActiveRecord::Rollback unless @error_messages.empty?
    end

    if @error_messages.empty?
      flash[:notice] = _('保存しました。')
      redirect_to :action => params[:tab] ? params[:tab] : 'index'
    else
      render :action => 'index'
    end
  end

  def ado_feed_item
    @feed_setting = {:url => '', :title => ''}
    @index =  params[:index]
    render :partial => 'feed_item'
  end

  def current_setting symbolize_key
    value = @current_setting_hash[symbolize_key] || ERB::Util.h(Admin::Setting.send(symbolize_key.to_s))
    if value == 'true'
      true
    elsif value == 'false'
      false
    else
      value
    end
  end

  private
  def has_empty_value?(array)
    array.each do |value|
      return true if value.blank?
    end
    false
  end

  # システム情報の表示項目を返す
  def setting_of key, value=nil
    { :label => _("#{Admin::InitialSetting.name}|#{key.humanize}"),
      :help => _("#{Admin::InitialSetting.name}|#{key.humanize} description"),
      :value => value ? value : _("#{Admin::InitialSetting.name}|#{key.humanize}|#{SkipEmbedded::InitialSettings[key]}")
    }
  end
end
