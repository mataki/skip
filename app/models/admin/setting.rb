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

class Admin::Setting < ActiveRecord::Base
  # ================================================================================================
  # 通常のカラム
  # ================================================================================================
  N_('Admin::Setting|Value')

  # ================================================================================================
  # 全体設定用
  # ================================================================================================
  # 名称,名前
  N_('Admin::Setting|Abbr app title')
  N_('Admin::Setting|Abbr app title description')
  N_('Admin::Setting|Login account')
  N_('Admin::Setting|Login account description')
  N_('Admin::Setting|Point button')
  N_('Admin::Setting|Point button description')

  # お問い合わせ,ヘルプ
  N_('Admin::Setting|Contact addr')
  N_('Admin::Setting|Contact addr description')
  N_('Admin::Setting|Help url')
  N_('Admin::Setting|Help url description')

  # フッター
  N_('Admin::Setting|Footer first')
  N_('Admin::Setting|Footer first description')
  N_('Admin::Setting|Footer second')
  N_('Admin::Setting|Footer second description')

  # メール関連の設定用
  N_('Admin::Setting|Contact mail contain contents')
  N_('Admin::Setting|Contact mail contain contents description')
  N_('Admin::Setting|Host and port')
  N_('Admin::Setting|Host and port description')
  N_('Admin::Setting|Protocol')
  N_('Admin::Setting|Protocol description')

  # その他
  N_('Admin::Setting|Stop new user')
  N_('Admin::Setting|Stop new user description')
  N_('Admin::Setting|Hide email')
  N_('Admin::Setting|Hide email description')
  N_('Admin::Setting|Activation lifetime')
  N_('Admin::Setting|Activation lifetime description')
  N_('Admin::Setting|Enable change picture')
  N_('Admin::Setting|Enable change picture description')
  N_('Admin::Setting|Enable change section')
  N_('Admin::Setting|Enable change section description')
  N_('Admin::Setting|Access record limit')
  N_('Admin::Setting|Access record limit description')
  N_('Admin::Setting|Entry showed tab limit per page')
  N_('Admin::Setting|Entry showed tab limit per page description')

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
  # セキュリティ設定
  # ================================================================================================
  N_('Admin::Setting|Enable user lock')
  N_('Admin::Setting|Enable user lock description')
  N_('Admin::Setting|User lock trial limit')
  N_('Admin::Setting|User lock trial limit description')
  N_('Admin::Setting|Enable password periodic change')
  N_('Admin::Setting|Enable password periodic change description')
  N_('Admin::Setting|Password change interval')
  N_('Admin::Setting|Password change interval description')
  N_('Admin::Setting|Password strength')
  N_('Admin::Setting|Password strength description')
  N_('Admin::Setting|Password strength|high')
  N_('Admin::Setting|Password strength|Validation message high')
  N_('Admin::Setting|Password strength|middle')
  N_('Admin::Setting|Password strength|Validation message middle')
  N_('Admin::Setting|Password strength|low')
  N_('Admin::Setting|Password strength|Validation message low')
  N_('Admin::Setting|Password strength|custom')
  N_('Admin::Setting|Custom password strength regex')
  N_('Admin::Setting|Custom password strength regex description')
  N_('Admin::Setting|Custom password strength validation message')
  N_('Admin::Setting|Custom password strength validation message description')
  N_('Admin::Setting|Enable login keyphrase')
  N_('Admin::Setting|Enable login keyphrase description')
  N_('Admin::Setting|Login keyphrase')
  N_('Admin::Setting|Login keyphrase description')
  N_('Admin::Setting|Enable user cleaning notification')
  N_('Admin::Setting|Enable user cleaning notification description')
  N_('Admin::Setting|User cleaning notification interval')
  N_('Admin::Setting|User cleaning notification interval description')
  N_('Admin::Setting|Enable single session')
  N_('Admin::Setting|Enable single session description')

  cattr_accessor :available_settings
  @@available_settings = YAML::load(File.open("#{RAILS_ROOT}/config/settings.yml"))

  SMTP_AUTHENTICATIONS = %w(plain login cram_md5).freeze
  PASSWORD_STRENGTH_VALUES = %w(low middle high custom).freeze

  validates_uniqueness_of :name
  validates_inclusion_of :name, :in => @@available_settings.keys

  validates_numericality_of :value, :only_integer => true, :greater_than => 0, :if => Proc.new { |setting| @@available_settings[setting.name]['format'] == 'int' }
  validates_format_of :value,
                      :with => URI.regexp(['http', 'https']),
                      :if => Proc.new { |setting| @@available_settings[setting.name]['format'] == 'url' && !@@available_settings[setting.name]['allow_blank'].nil? },
                      :allow_blank => true

  validates_format_of :value,
                      :with => URI.regexp(['http', 'https']),
                      :if => Proc.new { |setting| @@available_settings[setting.name]['format'] == 'url' && @@available_settings[setting.name]['allow_blank'].nil? }

  validates_presence_of :value, :if => Proc.new{ |setting| setting.class.password_strength == 'custom' && setting.name == 'custom_password_strength_regex' || setting.name == 'custom_password_strength_validation_message' }

  validates_format_of :value, :with => Authentication.email_regex, :if => Proc.new { |setting| @@available_settings[setting.name]['format'] == 'email' }

  # Hash used to cache setting values
  @cached_settings = {}
  @cached_cleared_on = Time.now

  def validate
    v = read_attribute(:value)
    if @@available_settings[name]['format'] == 'regex' && !v.blank?
      begin
        Regexp.compile(v)
      rescue RegexpError => e
        errors.add('value', _('requires a valid regular expression.'))
      end
    end
  end

  def after_save
    ActionController::Base.expire_page  '/services/skip_reflect_customized.js'
  end

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
    SkipEmbedded::InitialSettings['host_and_port'] || self.host_and_port
  end

  def self.protocol_by_initial_settings_default
    SkipEmbedded::InitialSettings['protocol'] || self.protocol
  end

  def self.password_strength_regex
    lower = 'a-z'
    lower_negative_lookahead = "(?!^[^#{lower}]*$)"
    upper = 'A-Z'
    upper_negative_lookahead = "(?!^[^#{upper}]*$)"
    digit = '0-9'
    digit_negative_lookahead = "(?!^[^#{digit}]*$)"
    symbol = '!@#\$%\^&\*\?_~'
    symbol_negative_lookahead = "(?!^[^#{symbol}]*$)"
    lower_upper_digit_symbol = "#{lower}#{upper}#{digit}#{symbol}"
    low_regex_s = "^[#{lower_upper_digit_symbol}]{6,}$"
    middle_regex_s = "#{lower_negative_lookahead}#{upper_negative_lookahead}#{digit_negative_lookahead}^[#{lower_upper_digit_symbol}]{8,}$"
    high_regex_s = "#{symbol_negative_lookahead}#{middle_regex_s}"
    case password_strength
      when 'low' then /#{low_regex_s}/
      when 'middle' then /#{middle_regex_s}/
      when 'high' then /#{high_regex_s}/
      when 'custom' then /#{Admin::Setting.custom_password_strength_regex}/
      else /#{middle_regex_s}/
    end
  end

  def self.password_strength_validation_error_message
    if PASSWORD_STRENGTH_VALUES.include? Admin::Setting.password_strength
      if Admin::Setting.password_strength == 'custom'
        Admin::Setting.custom_password_strength_validation_message
      else
        _('Admin::Setting|Password strength|Validation message ' + password_strength)
      end
    else
      _('Admin::Setting|Password strength|Validation message middle')
    end
  end

  def self.error_messages(settings)
    settings.map do |setting|
      _("#{Admin::Setting}|#{setting.name.humanize}") + setting.errors.on('value') unless setting.valid?
    end.compact
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
