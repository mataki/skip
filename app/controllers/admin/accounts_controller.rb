class Admin::AccountsController < ApplicationController
  include AdminModule::AdminRootModule
  before_filter :require_admin
end
