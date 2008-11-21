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

class Admin::Setting < ActiveRecord::Base
  # ================================================================================================
  # 全体設定用
  # ================================================================================================
  N_('Admin::Setting|Stop new user')
  N_('Admin::Setting|Stop new user description')
  N_('Admin::Setting|Enable activation')
  N_('Admin::Setting|Enable activation description')

  # ================================================================================================
  # 各種文言の設定用
  # ================================================================================================
  N_('Admin::Setting|Abbr app title')
  N_('Admin::Setting|Abbr app title description')
  N_('Admin::Setting|Contact addr')
  N_('Admin::Setting|Contact addr description')
  N_('Admin::Setting|Help url')
  N_('Admin::Setting|Help url description')
  N_('Admin::Setting|Initial anntena')
  N_('Admin::Setting|Initial anntena description')
  N_('Admin::Setting|Login account')
  N_('Admin::Setting|Login account description')
  N_('Admin::Setting|Footer link')
  N_('Admin::Setting|Footer link description')
  N_('Admin::Setting|Footer contact')
  N_('Admin::Setting|Footer contact description')
  N_('Admin::Setting|Footer copyright')
  N_('Admin::Setting|Footer copyright description')
  N_('Admin::Setting|Footer image link url')
  N_('Admin::Setting|Footer image link url description')
  N_('Admin::Setting|Point button')
  N_('Admin::Setting|Point button description')

  # ================================================================================================
  # メール関連の設定用
  # ================================================================================================
  N_('Admin::Setting|Mail function setting')
  N_('Admin::Setting|Mail function setting description')
  N_('Admin::Setting|Smtp settings')
  N_('Admin::Setting|Smtp settings description')
  N_('Admin::Setting|Smtp settings password')
  N_('Admin::Setting|Smtp settings password description')
  N_('Admin::Setting|Smtp settings port')
  N_('Admin::Setting|Smtp settings port description')
  N_('Admin::Setting|Smtp settings user name')
  N_('Admin::Setting|Smtp settings user name description')
  N_('Admin::Setting|Smtp settings address')
  N_('Admin::Setting|Smtp settings address description')
  N_('Admin::Setting|Smtp settings domain')
  N_('Admin::Setting|Smtp settings domain description')
  N_('Admin::Setting|Smtp settings authentication')
  N_('Admin::Setting|Smtp settings authentication description')
  N_('Admin::Setting|Host and port')
  N_('Admin::Setting|Host and port description')
  N_('Admin::Setting|Protocol')
  N_('Admin::Setting|Protocol description')

  # ================================================================================================
  # RSSフィードの設定用
  # ================================================================================================
  N_('Admin::Setting|Mypage feed default limit')
  N_('Admin::Setting|Mypage feed default limit description')
  N_('Admin::Setting|Mypage feed timeout')
  N_('Admin::Setting|Mypage feed timeout description')
  N_('Admin::Setting|Mypage feed settings')
  N_('Admin::Setting|Mypage feed settings description')
  N_('Admin::Setting|Mypage feed settings url')
  N_('Admin::Setting|Mypage feed settings url description')
  N_('Admin::Setting|Mypage feed settings title')
  N_('Admin::Setting|Mypage feed settings title description')

  # ================================================================================================
  # その他設定
  # ================================================================================================
  N_('Admin::Setting|Antenna settings')
  N_('Admin::Setting|Antenna default group')
  N_('Admin::Setting|Antenna default group description')

  cattr_accessor :available_settings
  @@available_settings = YAML::load(File.open("#{RAILS_ROOT}/config/settings.yml"))

  validates_uniqueness_of :name
  validates_inclusion_of :name, :in => @@available_settings.keys

  validates_numericality_of :value, :only_integer => true, :if => Proc.new { |setting| @@available_settings[setting.name]['format'] == 'int' }
  validates_format_of :value,
                      :with => URI.regexp(['http', 'https']),
                      :if => Proc.new { |setting| @@available_settings[setting.name]['format'] == 'url' && !@@available_settings[setting.name]['allow_blank'].nil? },
                      :allow_blank => true

  validates_format_of :value,
                      :with => URI.regexp(['http', 'https']),
                      :if => Proc.new { |setting| @@available_settings[setting.name]['format'] == 'url' && @@available_settings[setting.name]['allow_blank'].nil? }

  # Hash used to cache setting values
  @cached_settings = {}
  @cached_cleared_on = Time.now

  def value
    v = read_attribute(:value)
    # Unserialize serialized settings
    v = YAML::load(v) if @@available_settings[name]['serialized'] && v.is_a?(String)
    v = v.to_sym if @@available_settings[name]['format'] == 'symbol' && !v.blank?
    v = v.to_i if @@available_settings[name]['format'] == 'int' && !v.blank?
    v = (v == 'true') if @@available_settings[name]['format'] == 'boolean' && !v.blank?
    v
  end

  def value=(v)
    v = v.to_yaml if v && @@available_settings[name]['serialized']
    write_attribute(:value, v.to_s)
  end

  # Returns the value of the setting named name
  def self.[](name)
    v = @cached_settings[name]
    v ? v : (@cached_settings[name] = find_or_default(name).value)
  end

  def self.[]=(name, v)
    setting = find_or_default(name)
    setting.value = (v ? v : "")
    @cached_settings[name] = nil
    setting.save
    setting
  end

  # Defines getter and setter for each setting
  # Then setting values can be read using: Setting.some_setting_name
  # or set using Setting.some_setting_name = "some value"
  @@available_settings.each do |name, params|
    src = <<-END_SRC
    def self.#{name}
      self[:#{name}]
    end

    def self.default_#{name}
      self.available_settings['#{name}']['default']
    end

    def self.#{name}?
      self[:#{name}] == 'true'
    end

    def self.#{name}=(value)
      self[:#{name}] = value
    end
    END_SRC
    class_eval src, __FILE__, __LINE__
  end

  # Checks if settings have changed since the values were read
  # and clears the cache hash if it's the case
  # Called once per request
  def self.check_cache
    settings_updated_on = Admin::Setting.maximum(:updated_at)
    if settings_updated_on && @cached_cleared_on <= settings_updated_on
      @cached_settings.clear
      @cached_cleared_on = Time.now
      logger.info "Settings cache cleared." if logger
    end
  end

  def self.host_and_port_by_initial_settings_default
    INITIAL_SETTINGS['host_and_port'] || self.host_and_port
  end

  def self.protocol_by_initial_settings_default
    INITIAL_SETTINGS['protocol'] || self.protocol
  end

  private
  # Returns the Setting instance for the setting named name
  # (record found in database or new record with default value)
  def self.find_or_default(name)
    name = name.to_s
    raise "There's no setting named #{name}" unless @@available_settings.has_key?(name)
    setting = find_by_name(name)
    setting ||= new(:name => name, :value => @@available_settings[name]['default'])
  end
end
