class CustomizesController < ApplicationController
  def update
    @user_custom = current_user.custom
    if @user_custom.update_attributes(params[:user_custom])
      setup_custom_cookies(@user_custom)
      flash[:notice] = _('Updated successfully.')
    end
    redirect_to root_url
  end
end
