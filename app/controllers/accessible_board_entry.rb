module AccessibleBoardEntry
  def current_target_entry
    @board_entry ||= BoardEntry.find(params[:board_entry_id] || params[:id])
  end

  def required_full_accessible board_entry = current_target_entry
    if result = board_entry.full_accessible?(current_user)
      yield if block_given?
    else
      respond_to do |format|
        format.html { redirect_to_with_deny_auth }
        format.js { render :text => _('Operation unauthorized.'), :status => :forbidden }
      end
    end
    result
  end

  def required_accessible board_entry = current_target_entry
    if result = board_entry.accessible?(current_user)
      yield if block_given?
    else
      respond_to do |format|
        format.html { redirect_to_with_deny_auth }
        format.js { render :text => _('Operation unauthorized.'), :status => :forbidden }
      end
    end
    result
  end

  def required_accessible_without_writer board_entry = current_target_entry
    if result = board_entry.accessible_without_writer?(current_user)
      yield if block_given?
    else
      respond_to do |format|
        format.html { redirect_to_with_deny_auth }
        format.js { render :text => _('Operation unauthorized.'), :status => :forbidden }
      end
    end
    result
  end
end
