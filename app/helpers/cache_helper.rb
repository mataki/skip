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

module CacheHelper
  PROTOTYPE_LIBRARY = {:name => 'prototype.all', :libs => ['prototype']}

  JQUERY_LIBRARY = {:name => 'jquery.all',
    :libs => %w(jquery jquery.cookie jquery.color jquery.bgiframe jquery.autocomplete jquery.jTagging jquery.jgrow jquery.cluetip ui.core ui.tabs ui.dialog jquery.fitimage jquery.iphone-style-checkboxes jquery.jeditable)}

  STYLE_LIBRARY = {:name => 'skip.style', :libs => %w(application skins-base)}

  def all_javascript_include_tag source
    library = {'prototype' => PROTOTYPE_LIBRARY, 'jquery' => JQUERY_LIBRARY}[source]
    if source == 'jquery'
      lib_str = library[:libs].map { |lib| skip_jquery_path lib }
    else
      lib_str = library[:libs].map { |lib| "/javascripts/skip/#{lib}" }
    end
    lib_str << {:cache => library[:name]}
    javascript_include_tag(*lib_str)
  end

  # TODO sourceが意味をなしてない。リファクタする
  def all_stylesheet_link_tag source
    library = {'style' => STYLE_LIBRARY }[source]
    lib_str = []
    library[:libs].each do |lib|
      lib_str << "/stylesheets/#{lib}"
    end
    lib_str << {:cache => library[:name]}
    stylesheet_link_tag(*lib_str)
  end
end
