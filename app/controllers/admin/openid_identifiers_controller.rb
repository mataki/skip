class Admin::OpenidIdentifiersController < ApplicationController
  before_filter :load_parent, :require_admin
  include AdminModule::AdminChildModule

  private

  def load_parent
    @account ||= Admin::Account.find(params[:account_id])
  end

  def url_prefix
    'admin_account_'
  end

end
