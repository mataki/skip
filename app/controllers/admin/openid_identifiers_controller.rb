class Admin::OpenidIdentifiersController < ApplicationController
  before_filter :load_account, :require_admin
  # GET /admin_openid_identifiers
  # GET /admin_openid_identifiers.xml
  def index
    @openid_identifiers = @account.openid_identifiers

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @openid_identifiers }
    end
  end

  # GET /admin_openid_identifiers/1
  # GET /admin_openid_identifiers/1.xml
  def show
    @openid_identifier = @account.openid_identifiers.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @openid_identifier }
    end
  end

  # GET /admin_openid_identifiers/new
  # GET /admin_openid_identifiers/new.xml
  def new
    @openid_identifier = Admin::OpenidIdentifier.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @openid_identifier }
    end
  end

  # GET /admin_openid_identifiers/1/edit
  def edit
    @openid_identifier = @account.openid_identifiers.find(params[:id])
  end

  # POST /admin_openid_identifiers
  # POST /admin_openid_identifiers.xml
  def create
    @openid_identifier = @account.openid_identifiers.build(params[:admin_openid_identifier])

    respond_to do |format|
      if @openid_identifier.save
        flash[:notice] = 'Admin::OpenidIdentifier was successfully created.'
        format.html { redirect_to(admin_account_openid_identifier_url(load_account, @openid_identifier)) }
        format.xml  { render :xml => @openid_identifier, :status => :created, :location => @openid_identifier }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @openid_identifier.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /admin_openid_identifiers/1
  # PUT /admin_openid_identifiers/1.xml
  def update
    @openid_identifier = @account.openid_identifiers.find(params[:id])

    respond_to do |format|
      if @openid_identifier.update_attributes(params[:openid_identifier])
        flash[:notice] = 'Admin::OpenidIdentifier was successfully updated.'
        format.html { redirect_to(admin_account_openid_identifier_url(load_account, @openid_identifier)) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @openid_identifier.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /admin_openid_identifiers/1
  # DELETE /admin_openid_identifiers/1.xml
  def destroy
    @openid_identifier = @account.openid_identifiers.find(params[:id])
    @openid_identifier.destroy

    respond_to do |format|
      format.html { redirect_to(admin_account_openid_identifiers_url(load_account)) }
      format.xml  { head :ok }
    end
  end

  private

  def load_account
    @account = Admin::Account.find(params[:account_id])
  end
end
