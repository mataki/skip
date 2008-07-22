# SKIP(Social Knowledge & Innovation Platform)
# Copyright (C) 2008  TIS Inc.
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

module UsersHelper

  def output_users_result output_normal, users
    output = ""
    if output_normal
      for user in users
        output << render( :partial => "users/user",
                          :object => user )
      end
    else
      table_columns = [ "uid", "name", "code", "email", "section", "extension" ]
      block = lambda{ |user, column|
        case column
        when "name"
          user_link_to user
        when "email"
          %(<a href="mailto:#{user.email}">#{user.email}</a>)
        else
          h(user.send(column))
        end
      }
      output = render( :partial => "shared/table",
                       :locals => { :records => users,
                                    :target_class => User,
                                    :table_columns => table_columns,
                                    :value_logic => block  } )
    end
    output
  end
end
