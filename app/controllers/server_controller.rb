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

class ServerController < ApplicationController
  # CSRF-protection must be skipped, because incoming
  # OpenID requests lack an authenticity token
  skip_before_filter :verify_authenticity_token
  # Error handling
  rescue_from OpenID::Server::ProtocolError, :with => :render_openid_error
  # Actions other than index require a logged in user
  skip_before_filter :sso, :login_required, :prepare_session, :only => [:index, :cancel]
  skip_after_filter :remove_message
  before_filter :ensure_valid_checkid_request, :except => [:index, :cancel]
  after_filter :clear_checkid_request, :only => [:cancel]
  # These methods are used to display information about the request to the user
  helper_method :sreg_request, :ax_fetch_request

  # This is the server endpoint which handles all incoming OpenID requests.
  # Associate and CheckAuth requests are answered directly - functionality
  # therefor is provided by the ruby-openid gem. Handling of CheckId requests
  # dependents on the users login state (see handle_checkid_request).
  # Yadis requests return information about this endpoint.
  def index
    clear_checkid_request
    respond_to do |format|
      format.html do
        if openid_request.is_a?(OpenID::Server::CheckIDRequest)
          handle_checkid_request
        elsif openid_request
          handle_non_checkid_request
        else
          render :text => _('This is an OpenID server endpoint, not a human readable resource.')
        end
      end
      format.xrds do
        render :layout => false
      end
    end
  end

  # This action decides how to process the current request and serves as
  # dispatcher and re-entry in case the request could not be processed
  # directly (for instance if the user had to log in first).
  # When the user has already trusted the relying party, the request will
  # be answered based on the users release policy. If the request is immediate
  # (relying party wants no user interaction, used e.g. for ajax requests)
  # the request can only be answered if no further information (like simple
  # registration data) is requested. Otherwise the user will be redirected
  # to the decision page.
  def proceed
    identity = identifier(current_user)
    if SkipEmbedded::InitialSettings['white_list'].include? checkid_request.trust_root
      resp = checkid_request.answer(true, nil, identity)
      props = convert_ax_props(current_user)
      resp = add_ax(resp, props)
      render_response(resp)
    elsif checkid_request.immediate && (sreg_request || ax_fetch_request)
      render_response(checkid_request.answer(false))
    elsif checkid_request.immediate
      render_response(checkid_request.answer(true, nil, identity))
    else
      flash[:error] = _("This site is not allowed")
      redirect_to root_url
    end
  end

  def cancel
    redirect_to checkid_request.cancel_url
  end
  protected

  # Decides how to process an incoming checkid request. If the user is
  # already logged in he will be forwarded to the proceed action. If
  # the user is not logged in and the request is immediate, the request
  # cannot be answered successfully. In case the user is not logged in,
  # the request will be stored and the user is asked to log in.
  def handle_checkid_request
    if allow_verification?
      save_checkid_request
      redirect_to proceed_path
    elsif openid_request.immediate
      render_response(openid_request.answer(false))
    else
      save_checkid_request
      redirect_to login_path(:return_to => URI.encode(proceed_path))
    end
  end

  # Stores the current OpenID request
  def save_checkid_request
    clear_checkid_request
    session[:request_token] = OpenIdRequest.create(:parameters => openid_params).token
  end

  # Deletes the old request when a new one comes in.
  def clear_checkid_request
    unless session[:request_token].blank?
      OpenIdRequest.destroy_all :token => session[:request_token]
      session[:request_token] = nil
    end
  end

  # Use this as before_filter for every CheckID request based action.
  # Loads the current openid request and cancels if none can be found.
  # The user has to log in, if he has not verified his ownership of
  # the identifier, yet.
  def ensure_valid_checkid_request
    self.openid_request = checkid_request
    if !openid_request.is_a?(OpenID::Server::CheckIDRequest)
      flash[:error] = 'The identity verification request is invalid.'
      redirect_to login_path
    elsif !allow_verification?
      flash[:notice] = logged_in? && !pape_requirements_met?(auth_time) ?
        'The Service Provider requires reauthentication, because your last login is too long ago.' :
        'Please log in to verify your identity.'
      logout_killing_session!([:request_token])
      redirect_to login_path(:return_to => URI.encode(proceed_path))
    end
  end

  # The user must be logged in, he must be the owner of the claimed identifier
  # and the PAPE requirements must be met if applicable.
  def allow_verification?
    logged_in? && correct_identifier? && pape_requirements_met?(auth_time)
  end

  # Is the user allowed to verify the claimed identifier? The user
  # must be logged in, so that we know his identifier or the identifier
  # has to be selected by the server (id_select).
  def correct_identifier?
    (openid_request.identity == identifier(current_user) || openid_request.id_select)
  end

  # Clears the stored request and answers
  def render_response(resp)
    clear_checkid_request
    render_openid_response(resp)
  end

  # Renders the exception message as text output
  def render_openid_error(exception)
    error = case exception
    when OpenID::Server::MalformedTrustRoot: "Malformed trust root '#{exception.to_s}'"
    else exception.to_s
    end
    render :text => "Invalid OpenID request: #{error}", :status => 500
  end

  private

  # The NIST Assurance Level, see:
  # http://openid.net/specs/openid-provider-authentication-policy-extension-1_0-01.html#anchor12
  def auth_level
    SkipEmbedded::InitialSettings['protocol'] == "https://" ? 2 : 0
  end

  def auth_time
    current_user.last_authenticated_at
  end

  def auth_policies
    []
  end

  def convert_ax_props(user, from = SkipEmbedded::InitialSettings['ax_props'])
    hash = {}
    from.each do |i|
      hash["type.#{i[0]}"] = i[1]
      hash["value.#{i[0]}"] = user.send(i[2].to_sym)
    end
    hash
  end
end
