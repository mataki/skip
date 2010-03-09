module AccessibleBoardEntry
  def current_target_entry
    @board_entry ||= BoardEntry.find(params[:board_entry_id] || params[:id])
  end

  def required_full_accessible board_entry = current_target_entry
    if result = board_entry.full_accessible?(current_user)
      yield if block_given?
    else
      redirect_to_with_deny_auth
    end
    result
  end

  def required_accessible board_entry = current_target_entry
    if result = board_entry.accessible?(current_user)
      yield if block_given?
    else
      redirect_to_with_deny_auth
    end
    result
  end
end
