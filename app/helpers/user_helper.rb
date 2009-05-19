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

module UserHelper
  include BoardEntriesHelper

  # メニューの生成
  def get_social_menu_items selected_menu
    @@menus = [{:name => "他の人からの紹介文",     :menu => "social_chain" },
               {:name => "他の人への紹介文",   :menu => "social_chain_against" },
               {:name => "他の人からの印象",       :menu => "social_postit" },
              ]
    get_menu_items @@menus, selected_menu, "social"
  end

  def social_tag_cloud tags, uid
    output = ""
    tag_cloud tags do |name, count, css_class|
      if params[:selected_tag] == name
        output << '<span style="background-color: yellow;">'
        output << link_to(name, {:action => :social, :uid => uid, :menu => 'social_postit'}, :class => css_class)
        output << '</span>'
      else
        output << link_to(name, {:action => :social, :uid => uid, :menu => 'social_postit', :selected_tag => name}, :class => css_class)
      end
      output << "<span style='color: silver; font-size: 10px;'>(#{count})</span> "
    end
    output
  end

  def profile_show_tag input_type_processer, user_profile_value
    if input_type_processer.class == UserProfileMaster::RichTextProcesser
      value_str = user_profile_value ? user_profile_value.value : ""
      symbol = user_profile_value ? user_profile_value.user.symbol : nil
      content_tag(:div, render_richtext(value_str, symbol), :class => "input_value rich_value")
    else
      value_str = user_profile_value ? user_profile_value.value : ""
      content_tag(:div, h(value_str), :class => "input_value") + content_tag(:div, nil, :class => "input_bottom")
    end
  end
end
