class Admin::GroupParticipationsController < ApplicationController
  before_filter :load_parent, :require_admin
  include AdminModule::AdminChildModule

  private

  def load_parent
    @group ||= Admin::Group.find(params[:group_id])
  end

  def url_prefix
    'admin_group_'
  end

end
