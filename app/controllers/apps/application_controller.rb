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

class Apps::ApplicationController < ApplicationController

  protected
  def proxy_request_to_simple_apps
    client = HTTPClient.new
    apps_url = "#{SkipEmbedded::InitialSettings['simple_apps']['url']}#{request.path}"
    common_headers = {'CsrfToken' => form_authenticity_token, 'SkipUserId' => current_user.id}
    res =
      if request.get?
        client.get(apps_url, request.query_parameters, common_headers)
      else
        if method = request.request_parameters['_method']
          # putかdeleteに限定すべきか?
          common_headers.merge!({'X-Http-Method-Override', method})
        end
        client.post(apps_url, request.request_parameters.to_json, common_headers.merge!({'Content-Type' => 'application/json'}))
      end
    if HTTPClient::HTTP::Status.successful?(res.status)
      respond_to do |format|
        format.html { render :inline => res.content + '<%= ckeditor \'.ckeditor_area\' %>', :layout => true }
        format.js { render :text => res.content, :layout => false }
        format.atom { render :text => res.content, :layout => false }
      end
    elsif HTTPClient::HTTP::Status.redirect?(res.status)
      respond_to do |format|
        format.html do
          uri = client.urify(request.url)
          new_uri = client.default_redirect_uri_callback(uri, res)
          new_uri.host =  uri.host
          new_uri.port = uri.port
          redirect_to new_uri.to_s
        end
      end
    else
      respond_to do |format|
        format.html { render :text => res.content, :layout => false }
        format.js { render :text => res.content, :layout => false }
      end
    end
  end
end
