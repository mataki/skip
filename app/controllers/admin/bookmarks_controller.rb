class Admin::BookmarksController < ApplicationController
  include AdminModule::AdminRootModule
  before_filter :require_admin
end
