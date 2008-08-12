# SKIP(Social Knowledge & Innovation Platform)
# Copyright (C) 2008 TIS Inc.
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program.  If not, see <http://www.gnu.org/licenses/>.

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe Admin::OpenidIdentifiersController do
  before do
    admin_login

    @openid_identifier = mock_model(OpenidIdentifier)

    @openid_identifiers = [@openid_identifier]

    @openid_identifiers.stub!(:to_xml).and_return("XML")
    @openid_identifiers.stub!(:find).and_return(@openid_identifier)

    @account = mock_model(Admin::Account)
    @account.stub!(:openid_identifiers).and_return(@openid_identifiers)
    Admin::Account.stub!(:find).and_return(@account)
  end
  describe "handling GET /admin_openid_identifiers" do

    before(:each) do
    end

    def do_get
      get :index
    end

    it "should be successful" do
      do_get
      response.should be_success
    end

    it "should render index template" do
      do_get
      response.should render_template('index')
    end

    it "should find all admin_openid_identifiers" do
      do_get
    end

    it "should assign the found admin_openid_identifiers for the view" do
      do_get
    end
  end

  describe "handling GET /admin_openid_identifiers.xml" do

    before(:each) do
    end

    def do_get
      @request.env["HTTP_ACCEPT"] = "application/xml"
      get :index
    end

    it "should be successful" do
      do_get
      response.should be_success
    end

    it "should find all admin_openid_identifiers" do
      do_get
    end

    it "should render the found admin_openid_identifiers as xml" do
      @openid_identifiers.should_receive(:to_xml).and_return("XML")
      do_get
      response.body.should == "XML"
    end
  end

  describe "handling GET /admin_openid_identifiers/1" do

    before(:each) do
    end

    def do_get
      get :show, :id => "1"
    end

    it "should be successful" do
      do_get
      response.should be_success
    end

    it "should render show template" do
      do_get
      response.should render_template('show')
    end

    it "should find the openid_identifier requested" do
      @openid_identifiers.should_receive(:find).with("1").and_return(@openid_identifier)
      do_get
    end

    it "should assign the found openid_identifier for the view" do
      do_get
      assigns[:openid_identifier].should equal(@openid_identifier)
    end
  end

  describe "handling GET /admin_openid_identifiers/1.xml" do

    before(:each) do

      @openid_identifier.stub!(:to_xml).and_return("XML")
    end

    def do_get
      @request.env["HTTP_ACCEPT"] = "application/xml"
      get :show, :id => "1"
    end

    it "should be successful" do
      do_get
      response.should be_success
    end

    it "should find the openid_identifier requested" do
      @openid_identifiers.should_receive(:find).with("1").and_return(@openid_identifier)
      do_get
    end

    it "should render the found openid_identifier as xml" do
      @openid_identifier.should_receive(:to_xml).and_return("XML")
      do_get
      response.body.should == "XML"
    end
  end

  describe "handling GET /admin_openid_identifiers/new" do

    before(:each) do
      Admin::OpenidIdentifier.stub!(:new).and_return(@openid_identifier)
    end

    def do_get
      get :new
    end

    it "should be successful" do
      do_get
      response.should be_success
    end

    it "should render new template" do
      do_get
      response.should render_template('new')
    end

    it "should not save the new openid_identifier" do
      @openid_identifier.should_not_receive(:save)
      do_get
    end

    it "should assign the new openid_identifier for the view" do
      do_get
      assigns[:openid_identifier].should equal(@openid_identifier)
    end
  end

  describe "handling GET /admin_openid_identifiers/1/edit" do

    before(:each) do
    end

    def do_get
      get :edit, :id => "1"
    end

    it "should be successful" do
      do_get
      response.should be_success
    end

    it "should render edit template" do
      do_get
      response.should render_template('edit')
    end

    it "should find the openid_identifier requested" do
      @openid_identifiers.should_receive(:find).and_return(@openid_identifier)
      do_get
    end

    it "should assign the found Admin::OpenidIdentifier for the view" do
      do_get
      assigns[:openid_identifier].should equal(@openid_identifier)
    end
  end

  describe "handling POST /admin_openid_identifiers" do

    before(:each) do
      @openid_identifiers.stub!(:build).and_return(@openid_identifier)
    end

    describe "with successful save" do

      def do_post
        @openid_identifier.should_receive(:save).and_return(true)
        post :create, :admin_openid_identifier => {}
      end

      it "should create a new openid_identifier" do
        @openid_identifiers.should_receive(:build).with({}).and_return(@openid_identifier)
        do_post
      end

      it "should redirect to the new openid_identifier" do
        do_post
        response.should redirect_to(admin_account_openid_identifier_url(@account, @openid_identifier))
      end

    end

    describe "with failed save" do

      def do_post
        @openid_identifier.should_receive(:save).and_return(false)
        post :create, :openid_identifier => {}
      end

      it "should re-render 'new'" do
        do_post
        response.should render_template('new')
      end

    end
  end

  describe "handling PUT /admin_openid_identifiers/1" do

    before(:each) do
    end

    describe "with successful update" do

      def do_put
        @openid_identifier.should_receive(:update_attributes).and_return(true)
        put :update, :id => "1"
      end

      it "should find the openid_identifier requested" do
        @openid_identifiers.should_receive(:find).with("1").and_return(@openid_identifier)
        do_put
      end

      it "should update the found openid_identifier" do
        do_put
        assigns(:openid_identifier).should equal(@openid_identifier)
      end

      it "should assign the found openid_identifier for the view" do
        do_put
        assigns(:openid_identifier).should equal(@openid_identifier)
      end

      it "should redirect to the openid_identifier" do
        do_put
        response.should redirect_to(admin_account_openid_identifier_url(@account, @openid_identifier))
      end

    end

    describe "with failed update" do

      def do_put
        @openid_identifier.should_receive(:update_attributes).and_return(false)
        put :update, :id => "1"
      end

      it "should re-render 'edit'" do
        do_put
        response.should render_template('edit')
      end

    end
  end

  describe "handling DELETE /admin_openid_identifiers/1" do

    before(:each) do
      @openid_identifier.stub!(:destroy)
      @openid_identifiers.stub!(:find).with("1").and_return(@openid_identifier)
    end

    def do_delete
      delete :destroy, :id => "1"
    end

    it "should find the openid_identifier requested" do
      @openid_identifiers.should_receive(:find).with("1").and_return(@openid_identifier)
      do_delete
    end

    it "should call destroy on the found openid_identifier" do
      @openid_identifier.should_receive(:destroy)
      do_delete
    end

    it "should redirect to the admin_openid_identifiers list" do
      do_delete
      response.should redirect_to(admin_account_openid_identifiers_url(@account))
    end
  end
end
