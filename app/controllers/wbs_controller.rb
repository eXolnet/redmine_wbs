class WbsController < ApplicationController
  default_search_scope :issues
  menu_item :wbs

  before_action :ensure_rest_api_is_available
  before_action :find_optional_project
  accept_api_auth :index

  def index
    respond_to do |format|
      format.html {
        render :layout => !request.xhr?
      }
      format.api  {
        @issues = @project.issues.visible.order("#{Issue.table_name}.root_id ASC, #{Issue.table_name}.lft ASC")
      }
    end
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  private

  def ensure_rest_api_is_available
    return if Setting.rest_api_enabled == "1"

    render_error :message => l(:error_rest_api_unavailable), :status => 403
  end
end
