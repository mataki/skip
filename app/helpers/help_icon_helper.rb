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

module HelpIconHelper
  include GetText
  include SkipEmbedded::Helpers

  def help_icon(object_name, method, content = nil, options = {})
    content ||= s_("#{object_name.to_s.classify}|#{method.to_s.humanize} description")
      help_icon_tag :content => content
  end
  def help_icon_tag options = {:title => '', :content => ''}
    icon_tag 'help', :title => "#{options[:title]}|#{options[:content]}"
  end
end
module ActionView
  module Helpers
    class FormBuilder
      def help_icon(method, content = nil, options = {})
        @template.help_icon(@object.class.name, method, content, objectify_options(options))
      end
    end
  end
end
