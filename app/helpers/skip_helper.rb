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

module SkipHelper

  # アイコンタグを参照する
  def icon_tag(name, options = {})
    result = content_tag(:span, '&nbsp;', {:class =>"ss_sprite ss_#{name}"}.merge(options))
    options[:margin] ? result + " " : result
  end

  # （images/skip以下に格納されている）画像を参照する
  def skip_image_tag(source, options = {})
    url = "/images/skip/#{source}"
    return options[:only_url] ? url : image_tag(url, options)
  end

  # （javascripts/skip以下に格納されている）JavaScriptを参照する
  def skip_javascript_include_tag source
    return skip_util_javascript_include_tag if source.include? 'skip_util'
    javascript_include_tag("/javascripts/skip/#{source}")
  end

  # （javascripts/skip/skip_util.js）を参照する
  def skip_util_javascript_include_tag
    <<-EOS
<script language="JavaScript" type="text/javascript">
<!--
var platform_url_root = '#{root_url.chop}';
//-->
</script>
#{javascript_include_tag('/javascripts/skip/skip_util')}
    EOS
  end

  def skip_jquery_include_tag source
    javascript_include_tag skip_jquery_path(source)
  end

  def skip_jquery_path source
    jquery_base_dir = '/javascripts/skip/jquery'
    if source == 'jquery'
      if ENV['RAILS_ENV'] == 'production'
        "#{jquery_base_dir}/#{source}.min.js"
      else
        "#{jquery_base_dir}/#{source}.js"
      end
    elsif ( (source =~ /^ui\./) == 0 || (source =~ /^effects\./) == 0 )
      if ENV['RAILS_ENV'] == 'production'
        "#{jquery_base_dir}/ui/minified/#{source}.min.js"
      else
        "#{jquery_base_dir}/ui/#{source}.js"
      end
    else
      if ENV['RAILS_ENV'] == 'production'
        "#{jquery_base_dir}/plugins/minified/#{source}.min.js"
      else
        "#{jquery_base_dir}/plugins/#{source}.js"
      end
    end
  end

  # （stylesheets/skip以下に格納されている）スタイルシートを参照する
  def skip_stylesheet_link_tag source
    stylesheet_link_tag("/stylesheets/skip/#{source}")
  end

  def link_to_hiki_help
    sub_window_script = get_subwindow_script "/hiki.html", 500, 600
    link_to '【本文の書き方に関するヒント】', "javascript:void(0)", :onclick => "#{sub_window_script}"
  end

  def get_subwindow_script url, width, height, title='subwindow'
    "sub_window = window.open('#{url}', title, 'width=#{width},height=#{height},resizable=yes,scrollbars=yes');sub_window.focus();"
  end

  def skip_menu_link
    javascript_include_tag("/services/menu.js")
  end

  def skip_footer_link
    javascript_include_tag("/services/footer.js")
  end

  # バリデーションエラーメッセージのテンプレートを置換する
  # app/views/system/_error_messages_for.rhtml が存在する前提
  def template_error_messages_for (object_name, options = {})
    #------------ 元のメソッドの内容そのまま
    options = options.symbolize_keys
    object = instance_variable_get("@#{object_name}")
    # ----------- ここまで
    unless object.errors.empty?
      render :partial => "system/error_messages_for",
      :locals=> { :messages=>object.errors.full_messages, :object=>object }
    end
  end
end
