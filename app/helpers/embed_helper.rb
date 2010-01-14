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

module EmbedHelper
  def flv_tag src
    <<-RUBY
<object width="425px" height="300px" id="player_api" data="#{relative_url_root}/flash/flowplayer-3.1.5.swf" type="application/x-shockwave-flash">
  <param name="allowfullscreen" value="true"/>
  <param name="allowscriptaccess" value="always"/>
  <param name="quality" value="high"/>
  <param name="cachebusting" value="false"/>
  <param name="bgcolor" value="#000000"/>
  <param name="movie" value="#{src}" />
  <param name="flashvars" value='config={"playerId":"player","clip":{"url":"#{src}"},"playlist":[{"url":"#{src}"}]}'/>
  <embed src='#{src}' type='application/x-shockwave-flash' width='425px' height='300px' allowfullscreen='true' allowscriptaccess='always' quality='high' cachebusting='false' bgcolor='#000000' flashvars='config={"playerId":"player","clip":{"url":"#{src}"},"playlist":[{"url":"#{src}"}]}'></embed>
</object>
    RUBY
  end

  def swf_tag src, options = {}
    options = {:width => 240, :height => 180}.merge(options)
    <<-RUBY
<object width='#{options[:width]}' height='#{options[:height]}'>
  <param name='movie' value='#{src}' />
  <embed src='#{src}' type='application/x-shockwave-flash' width='#{options[:width]}' height='#{options[:height]}' ></embed>
</object>
    RUBY
  end
end
