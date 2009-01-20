class IdsController < ApplicationController
  layout false
  skip_before_filter :sso, :login_required, :prepare_session
  skip_after_filter  :remove_message

  def show
    @user = User.find_by_code(params[:user])
    raise ActiveRecord::RecordNotFound if @user.nil?

    respond_to do |format|
      format.html do
        response.headers['X-XRDS-Location'] = formatted_identity_url(:user => @user.code, :format => :xrds, :protocol => scheme)
      end
      format.xrds
    end
  end
end
