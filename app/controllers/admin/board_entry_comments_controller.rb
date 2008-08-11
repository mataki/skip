class Admin::BoardEntryCommentsController < ApplicationController
  before_filter :require_admin
  before_filter :load_board_entry
  # GET /admin_board_entry_comments
  # GET /admin_board_entry_comments.xml
  def index
    @board_entry_comments = @board_entry.board_entry_comments

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @board_entry_comments }
    end
  end

  # GET /admin_board_entry_comments/1
  # GET /admin_board_entry_comments/1.xml
  def show
    @board_entry_comment = @board_entry.board_entry_comments.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @board_entry_comment }
    end
  end

  # GET /admin_board_entry_comments/new
  # GET /admin_board_entry_comments/new.xml
  def new
    @board_entry_comment = Admin::BoardEntryComment.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @board_entry_comment }
    end
  end

  # GET /admin_board_entry_comments/1/edit
  def edit
    @board_entry_comment = @board_entry.board_entry_comments.find(params[:id])
  end

  # POST /admin_board_entry_comments
  # POST /admin_board_entry_comments.xml
  def create
    @board_entry_comment = @board_entry.board_entry_comments.build(params[:admin_board_entry_comment])

    respond_to do |format|
      if @board_entry_comment.save
        flash[:notice] = 'Admin::BoardEntryComment was successfully created.'
        format.html { redirect_to(admin_board_entry_board_entry_comment_path(load_board_entry, @board_entry_comment)) }
        format.xml  { render :xml => @board_entry_comment, :status => :created, :location => @board_entry_comment }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @board_entry_comment.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /admin_board_entry_comments/1
  # PUT /admin_board_entry_comments/1.xml
  def update
    @board_entry_comment = @board_entry.board_entry_comments.find(params[:id])

    respond_to do |format|
      if @board_entry_comment.update_attributes(params[:admin_board_entry_comment])
        flash[:notice] = 'Admin::BoardEntryComment was successfully updated.'
        format.html { redirect_to(admin_board_entry_board_entry_comment_path(load_board_entry, @board_entry_comment)) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @board_entry_comment.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /admin_board_entry_comments/1
  # DELETE /admin_board_entry_comments/1.xml
  def destroy
    @board_entry_comment = @board_entry.board_entry_comments.find(params[:id])
    @board_entry_comment.destroy

    respond_to do |format|
      format.html { redirect_to(admin_board_entry_board_entry_comments_path(load_board_entry)) }
      format.xml  { head :ok }
    end
  end

  private
  def load_board_entry
    @board_entry ||= Admin::BoardEntry.find(params[:board_entry_id])
  end
end
