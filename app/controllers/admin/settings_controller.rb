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

# config/settings.ymlの内容をいくつかのビューにわけて表示/編集するコントローラ
# 具体的には全体設定、文言設定、メール関連設定、フィード設定、その他設定の各タブの
# 表示/更新を行う。
class Admin::SettingsController < Admin::ApplicationController
  N_('Admin::SettingsController|literal')
  N_('Admin::SettingsController|mail')
  N_('Admin::SettingsController|other')
  N_('Admin::SettingsController|feed')
  N_('Admin::SettingsController|main')

  def index
    @topics = [[s_("#{self.class.name}|#{params[:tab]}")]]
    if params[:tab].blank?
      redirect_to admin_settings_path(:tab => :literal)
    end

    if params[:tab] == 'main'
      @system_infos = []
      @system_infos << {
        :name => _("Shared Files Settings"),
        :settings => [{ :label => _("Current disk usage"),
                        :help => _("Showing the total capacity permitted for shared files versus current disk usage of shared files."),
                        :value => "#{ValidationsFile::FileSizeCounter.per_system/1.megabyte} / #{INITIAL_SETTINGS['max_share_file_size_of_system']/1.megabyte} (MB)"
                      },
                      setting_of('max_share_file_size_of_system', "#{INITIAL_SETTINGS['max_share_file_size_of_system'].to_i/1.megabyte}(MB)"),
                      setting_of('max_share_file_size_per_owner', "#{INITIAL_SETTINGS['max_share_file_size_per_owner'].to_i/1.megabyte}(MB)"),
                      setting_of('max_share_file_size', "#{INITIAL_SETTINGS['max_share_file_size'].to_i/1.megabyte}(MB)")
                     ]
      }
      @system_infos << {
        :name => _("Account Settings"),
        :settings => [setting_of('login_mode'),
                      login_mode?(:fixed_rp) ? setting_of('fixed_op_url', INITIAL_SETTINGS['fixed_op_url'] || _("Disable")) : nil,
                      setting_of('usercode_dips_setting'),
                      setting_of('password_edit_setting'),
                      setting_of('username_use_setting'),
                      setting_of('user_code_format_regex', INITIAL_SETTINGS['user_code_format_regex'] || _("Disable"))
                     ]
      }
      @system_infos << {
        :name => _("Functional Settings"),
        :settings => [setting_of('ssl_setting'),
                      setting_of('full_text_search_setting'),
                      setting_of('proxy_url', INITIAL_SETTINGS['proxy_url'] || _("Disable"))
                     ]
      }
      @system_infos << {
        :name => _("System Operation"),
        :settings => [setting_of('administrator_addr', INITIAL_SETTINGS['administrator_addr'] || _("Not Specified"))
                     ]
      }
    end
  end

  def update_all
    settings = (params[:settings] || {}).dup.symbolize_keys
    objects = settings.map do |name, value|
      # remove blank values in array settings
      value.delete_if {|v| v.blank? } if value.is_a?(Array)
      if [:antenna_default_group, :mypage_feed_settings].include? name
        value = {} if value.blank?
        value = value.values.delete_if { |item| (item.class == String) ? item.blank? : has_empty_value?(item.values) }
      end
      # Admin::Setting[name] = value と評価すると value の値がmapに収納されてしまうので
      Admin::Setting.[]=(name,value)
    end

    if objects.all? { |o| o.errors.empty? }
      flash[:notice] = _('Settings were saved successfully.')
    else
      flash[:error] = _('Error(s) occured while saving settings.')
    end

    if params[:tab] == 'mail'
      ActionMailer::Base.smtp_settings = {
        :address => Admin::Setting.smtp_settings_address,
        :domain => Admin::Setting.smtp_settings_domain,
        :port => Admin::Setting.smtp_settings_port,
        :user_name => Admin::Setting.smtp_settings_user_name,
        :password => Admin::Setting.smtp_settings_password,
        :authentication => Admin::Setting.smtp_settings_authentication }
    end

    redirect_to :action => params[:tab] ? params[:tab] : 'index'
  end

  def ado_feed_item
    @feed_setting = {:url => '', :title => ''}
    @index =  params[:index]
    render :partial => 'feed_item'
  end

  def ado_antenna_default_group
    @antenna = ''
    @index =  params[:index]
    render :partial => 'antenna_default_group'
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
    { :label => s_("#{Admin::InitialSetting.name}|#{key.humanize}"),
      :help => s_("#{Admin::InitialSetting.name}|#{key.humanize} description"),
      :value => value ? value : s_("#{Admin::InitialSetting.name}|#{key.humanize}|#{INITIAL_SETTINGS[key]}")
    }
  end

end
