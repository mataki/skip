class BoardEntryPointsController < ApplicationController
  include AccessibleBoardEntry
  layout false
  before_filter :required_accessible_without_writer, :only => %w(pointup)

  def pointup
    @board_entry.state.increment!(:point)
    respond_to do |format|
      format.html { render :partial => 'pointup' }
      format.js { render :text => "#{@board_entry.state.point} #{ERB::Util.html_escape(Admin::Setting.point_button)}" }
    end
  rescue ActiveRecord::RecordNotFound => ex
    respond_to do |format|
      format.html { render_404 }
      format.js { render :text => _('Target %{target} inexistent.')%{:target => _('board entry')}, :status => :not_found }
    end
  end
end
