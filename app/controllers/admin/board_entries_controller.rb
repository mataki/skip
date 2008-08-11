class Admin::BoardEntriesController < ApplicationController
  before_filter :require_admin
  # GET /admin_board_entries
  # GET /admin_board_entries.xml
  def index
    @board_entries = Admin::BoardEntry.find(:all)

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @board_entries }
    end
  end

  # GET /admin_board_entries/1
  # GET /admin_board_entries/1.xml
  def show
    @board_entry = Admin::BoardEntry.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @board_entry }
    end
  end

  # GET /admin_board_entries/new
  # GET /admin_board_entries/new.xml
  def new
    @board_entry = Admin::BoardEntry.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @board_entry }
    end
  end

  # GET /admin_board_entries/1/edit
  def edit
    @board_entry = Admin::BoardEntry.find(params[:id])
  end

  # POST /admin_board_entries
  # POST /admin_board_entries.xml
  def create
    @board_entry = Admin::BoardEntry.new(params[:admin_board_entry])

    respond_to do |format|
      if @board_entry.save
        flash[:notice] = 'Admin::BoardEntry was successfully created.'
        format.html { redirect_to(@board_entry) }
        format.xml  { render :xml => @board_entry, :status => :created, :location => @board_entry }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @board_entry.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /admin_board_entries/1
  # PUT /admin_board_entries/1.xml
  def update
    @board_entry = Admin::BoardEntry.find(params[:id])

    respond_to do |format|
      if @board_entry.update_attributes(params[:admin_board_entry])
        flash[:notice] = 'Admin::BoardEntry was successfully updated.'
        format.html { redirect_to(@board_entry) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @board_entry.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /admin_board_entries/1
  # DELETE /admin_board_entries/1.xml
  def destroy
    @board_entry = Admin::BoardEntry.find(params[:id])
    @board_entry.destroy

    respond_to do |format|
      format.html { redirect_to(admin_board_entries_url) }
      format.xml  { head :ok }
    end
  end
end
