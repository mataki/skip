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

module PicturesHelper
  def show_picture(user, options = {})
    options = {:border => '0', :name => 'picture', :alt => h(user.name), :fit_image => true}.merge(options)
    options.merge!(:class => 'fit_image') if options.delete(:fit_image)
    file_name =
      if picture = user.picture
        unless picture.new_record?
          tenant_user_picture_path(current_tenant, user, picture, :format => :png)
        else
          'default_picture.png'
        end
      else
        'default_picture.png'
      end
    image_tag(file_name, options)
  end
end
