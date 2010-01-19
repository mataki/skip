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

class UserProfileMaster < ActiveRecord::Base
  N_('UserProfileMaster|Input type|text_field')
  N_('UserProfileMaster|Input type|number_and_hyphen_only')
  N_('UserProfileMaster|Input type|rich_text')
  N_('UserProfileMaster|Input type|radio')
  N_('UserProfileMaster|Input type|year_select')
  N_('UserProfileMaster|Input type|select')
  N_('UserProfileMaster|Input type|appendable_select')
  N_('UserProfileMaster|Input type|check_box')
  N_('UserProfileMaster|Input type|prefecture_select')
  N_('UserProfileMaster|Input type|datepicker')

  N_('UserProfileMaster|Required|true')
  N_('UserProfileMaster|Required|false')

  has_many :user_profile_values, :dependent => :destroy
  belongs_to :user_profile_master_category

  validates_presence_of :name
  validates_presence_of :input_type
  validates_presence_of :sort_order
  validates_presence_of :user_profile_master_category_id

  default_scope :order => "user_profile_masters.sort_order"

  def validate
    validates_presence_of_category
    validates_presence_of_option_values
    validates_format_of_option_values
  end

  def name_with_escape
    ERB::Util.h(name)
  end

  def option_array
    option_values.split(',') if option_values
  end

  def option_array_with_blank
    required ? option_array : option_array.unshift("")
  end

  def self.input_type_option
    input_types.map{|key| [_("UserProfileMaster|Input type|#{key}"), key]}
  end

  def self.input_types
    %w(text_field number_and_hyphen_only rich_text check_box radio select appendable_select prefecture_select year_select datepicker)
  end

  def input_type_processer
    "UserProfileMaster::#{self.input_type.classify}Processer".constantize.new(self)
  rescue NameError => e
    logger.warn "UserProfileMaster - input_type is not selected from registered values"
    UserProfileMaster::InputTypeProcesser.new(self)
  end

  def self.input_type_processer_class(input_type)
    "UserProfileMaster::#{input_type.classify}Processer".constantize
  rescue NameError => e
    logger.warn "UserProfileMaster - input_type is not selected from registered values"
    UserProfileMaster::InputTypeProcesser
  end

  private
  def validates_presence_of_category
    unless category = UserProfileMasterCategory.find_by_id(self.user_profile_master_category_id)
      errors.add(:user_profile_master_category_id, _('does not exist in profile categories.'))
      return false
    end
    true
  end

  def validates_presence_of_option_values
    input_type_processer.validates_presence_of_option_values
  end

  def validates_format_of_option_values
    input_type_processer.validates_format_of_option_values
  end

  class InputTypeProcesser
    include ActionView::Helpers::TagHelper
    include ActionView::Helpers::FormTagHelper
    include ActionView::Helpers::FormOptionsHelper
    include GetText
    bindtextdomain 'skip'

    def initialize(master)
      @master = master
    end

    def to_edit_html(value)
      value_str = value ? value.value : ""
      text_field_tag("profile_value[#{@master.id}]", h(value_str))
    end

    def validate(value)
      value.errors.add_to_base(_("%{name} is mandatory.") % { :name => @master.name_with_escape }) if @master.required and value.value.blank?
    end

    def option_value_validate(value)
      value.errors.add_to_base(_("%{name} is mandatory.") % { :name => @master.name_with_escape }) if @master.required and value.value.blank?
      value.errors.add_to_base(_("%{name} contains value not in selectable options.") % { :name => @master.name_with_escape }) unless @master.option_array_with_blank.include?(value.value)
    end

    def self.need_option_values?
      false
    end

    def before_save(value)
    end

    def validates_presence_of_option_values
      @master.errors.add(:option_values, _('is mandatory.')) if self.class.need_option_values? && @master.option_values.blank?
    end

    def validates_format_of_option_values
    end
  end

  class TextFieldProcesser < InputTypeProcesser
  end

  class NumberAndHyphenOnlyProcesser < InputTypeProcesser
    def validate(value)
      value.errors.add_to_base(_("%{name} is mandatory.") % { :name => @master.name_with_escape }) if @master.required and value.value.blank?
      value.errors.add_to_base(_("%{name} accepts numbers and hiphens(\"-\") only.") % { :name => @master.name_with_escape }) unless value.value =~ /^[0-9\-]*$/
    end
  end

  class RadioProcesser < InputTypeProcesser
    alias :validate :option_value_validate

    def to_edit_html(value)
      value_str = value ? value.value : ""
      str = @master.option_array.inject("") do |result, val|
        result << radio_button_tag("profile_value[#{@master.id}]", val, val == value_str) + label_tag("profile_value_#{@master.id}_#{val}", ERB::Util.h(val))
      end
      str << content_tag(:a, _("uncheck selected"), :target => "profile_value[#{@master.id}]", :class => "cancel_radio") unless @master.required
      str
    end

    def self.need_option_values?
      true
    end
  end

  class RichTextProcesser < InputTypeProcesser
    def to_edit_html(value)
      value_str = value ? value.value : ""
      text_area_tag("profile_value[#{@master.id}]", value_str, :class => "invisible min_ckeditor")
    end
  end

  class YearSelectProcesser < InputTypeProcesser
    def to_edit_html(value)
      value_str = value ? value.value : ""
      select_tag("profile_value[#{@master.id}]", options_for_select(years, value_str))
    end

    def validate(value)
      if @master.required and value.value.blank?
        value.errors.add_to_base(_("%{name} is mandatory.") % { :name => @master.name_with_escape })
        return
      end
      value.errors.add_to_base(_("Enter %{name} in 4-digit numbers.") % { :name => @master.name_with_escape }) unless years.include?(value.value)
    end

    def self.need_option_values?
      true
    end

    def validates_format_of_option_values
      @master.errors.add(:option_values, _("accepts numbers and hiphens(\"-\") only.")) unless @master.option_values =~ /^(\d|-)*$/
    end

    private
    def years
      options = start_year <= end_year ? (start_year..end_year).to_a : (end_year..start_year).to_a.reverse
      @master.required ? options : [''] + options
    end

    def start_year
      start_year_and_end_year(@master.option_values).first
    end

    def end_year
      start_year_and_end_year(@master.option_values).last
    end

    def start_year_and_end_year value
      default_start_year = Time.now.year.to_s
      default_end_year = Time.now.year.to_s
      unless value.blank?
        start_year_and_end_year = value.split('-')
        if start_year_and_end_year.size == 1
          start_year = start_year_and_end_year.first
          end_year = default_end_year
          [start_year, end_year]
        elsif start_year_and_end_year.size > 1
          start_year = start_year_and_end_year.first.blank? ? default_start_year : start_year_and_end_year.first
          end_year = start_year_and_end_year[1].blank? ? default_end_year : start_year_and_end_year[1]
          [start_year, end_year]
        end
      else
        [default_start_year, default_end_year]
      end
    end
  end

  class SelectProcesser < InputTypeProcesser
    def to_edit_html(value)
      value_str = value ? value.value : ""
      select_tag("profile_value[#{@master.id}]", options_for_select(@master.option_array_with_blank, value_str))
    end

    def self.need_option_values?
      true
    end

    alias :validate :option_value_validate
  end

  class AppendableSelectProcesser < InputTypeProcesser
    include ActionView::Helpers::CaptureHelper

    def to_edit_html(value)
      value_str = value ? value.value : ""
      result = ""
      result << content_tag(:p, select_tag("profile_value[#{@master.id}]", options_for_select(registrated_select_option, value_str)) + _("Showing options from previously registered values")) unless registrated_select_option.blank?
      result << content_tag(:p, text_field_tag("profile_value[#{@master.id}]", (registrated_select_option.include?(value_str) ? "" : value_str), :class => "appendable_text") + _('Enter here if you cannot find the value in the options'))
    end

    private
    def registrated_select_option
      result = @master.user_profile_values.find(:all, :select => "count(*) as count, value", :group => "value", :order => "count DESC").map(&:value) || []
      @master.required ? result - [""] : result.unshift("").uniq
    end
  end

  class CheckBoxProcesser < InputTypeProcesser
    def to_edit_html(value)
      value_arr = value ? value.value : []
      value_arr = value_arr.split(',') if value_arr.is_a?(String)
      @master.option_array.inject("") do |result, val|
        result << check_box_tag("profile_value[#{@master.id}][]", val, value_arr.include?(val), :id => "profile_value_#{@master.id}_#{val}") + label_tag("profile_value_#{@master.id}_#{val}", ERB::Util.h(val))
      end
    end

    def validate(value)
      value.errors.add_to_base(_("%{name} is mandatory.") % { :name => @master.name_with_escape }) if @master.required and value.value.blank?
      unless value.value.blank? or value.value.is_a?(Array)
        value.errors.add_to_base(_("Invalid format for %{name}.") % {:name => @master.name_with_escape})
      else
        value_arr = value.value.blank? ? [] : value.value
        if (value_arr - @master.option_array).size > 0
          value.errors.add_to_base(_("%{name} contains value not in selectable options.") % { :name => @master.name_with_escape })
        end
      end
    end

    def self.need_option_values?
      true
    end

    def before_save(value)
      value_arr = value.value.blank? ? [] : value.value
      value.value = value_arr.join(',') if value_arr.is_a?(Array)
    end
  end

  class PrefectureSelectProcesser < InputTypeProcesser
    PREFECTURES = ["北海道", "青森県", "岩手県", "宮城県", "秋田県", "山形県", "福島県", "茨城県", "栃木県", "群馬県", "埼玉県", "千葉県", "東京都", "神奈川県", "新潟県", "富山県", "石川県", "福井県", "山梨県", "長野県", "岐阜県", "静岡県", "愛知県", "三重県", "滋賀県", "京都府", "大阪府", "兵庫県", "奈良県", "和歌山県", "鳥取県", "島根県", "岡山県", "広島県", "山口県", "徳島県", "香川県", "愛媛県", "高知県", "福岡県", "佐賀県", "長崎県", "熊本県", "大分県", "宮崎県", "鹿児島県", "沖縄県"].freeze
    def to_edit_html(value)
      value_str = value ? value.value : ""
      select_tag("profile_value[#{@master.id}]", options_for_select(prefectures, value_str))
    end

    def validate(value)
      if @master.required and value.value.blank?
        value.errors.add_to_base(_("%{name} is mandatory.") % { :name => @master.name_with_escape })
        return
      end
      value.errors.add_to_base(_("%{name} contains value not in selectable options.") % { :name => @master.name_with_escape }) unless prefectures.include?(value.value)
    end

    private
    def prefectures
      options = @master.required ? PREFECTURES : [''] + PREFECTURES
    end
  end

  class DatepickerProcesser < InputTypeProcesser
    def to_edit_html(value)
      value_str = value ? value.value : ""
      text_field_tag("profile_value[#{@master.id}]", h(value_str), :class => "datepicker", :id => "datepicker_#{@master.id}")
    end

    def validate(value)
      value.errors.add_to_base(_("%{name} is mandatory.") % { :name => @master.name_with_escape }) if @master.required and value.value.blank?
      begin
        Date.parse(value.value) unless value.value.blank?
      rescue ArgumentError => e
        value.errors.add_to_base(_("Enter %{name} in a valid date format.") % { :name => @master.name_with_escape })
      end
    end

    def before_save(value)
      value.value = Date.parse(value.value).strftime('%Y/%m/%d') unless value.value.blank?
    end
  end
end
