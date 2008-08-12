class Admin::GroupsController < ApplicationController
  include AdminModule::AdminRootModule
  before_filter :require_admin
end
