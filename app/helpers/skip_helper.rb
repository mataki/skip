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

module SkipHelper

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

  def skip_reflect_customized_javascript_include_tag
    javascript_include_tag(url_for(:controller => '/services', :action => 'skip_reflect_customized.js'))
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
    sub_window_script = get_subwindow_script "#{root_url}hiki.html", 500, 600
    link_to _('[Hints on writing entries]'), "javascript:void(0)", :onclick => "#{sub_window_script}"
  end

  def get_subwindow_script url, width, height, title='subwindow'
    "sub_window = window.open('#{url}', title, 'width=#{width},height=#{height},resizable=yes,scrollbars=yes');sub_window.focus();"
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

  def ckeditor target, opt = {}
    default_opt = {
      'customConfig' => url_for("/javascripts/skip_embedded/ckeditor_config.js"),
      'toolbar' => 'Entry'
    }.merge(opt)
    content_for :javascript_includes do
      javascript_include_tag "skip_embedded/ckeditor/ckeditor.js"
    end
    unless target =~ /\A\./
      content_for :javascript_initializers do
        "CKEDITOR.replace('#{target}', #{default_opt.to_json});"
      end
    else
      content_for :javascript_initializers do
        <<-EOF
jQuery('#{target}').each(function(){
    CKEDITOR.replace(this.id, #{default_opt.to_json});
});
EOF
      end
    end
  end

  # Google Analytics
  def google_analytics_tag
    unless (ga_code = SkipEmbedded::InitialSettings['google_analytics']).blank?
    <<-EOS
<script type="text/javascript">
var gaJsHost = (("https:" == document.location.protocol) ? "https://ssl." : "http://www.");
document.write(unescape("%3Cscript src='" + gaJsHost + "google-analytics.com/ga.js' type='text/javascript'%3E%3C/script%3E"));
</script>
<script type="text/javascript">
var pageTracker = _gat._getTracker("#{ga_code}");
pageTracker._initData();
pageTracker._trackPageview();
</script>
    EOS
    end
  end
end
