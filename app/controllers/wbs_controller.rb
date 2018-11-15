class WbsController < ApplicationController
  default_search_scope :issues
  menu_item :wbs

  before_action :ensure_rest_api_is_available
  before_action :find_optional_project
  before_action :build_default_tracker_id
  accept_api_auth :index

  def index
    respond_to do |format|
      format.html {
        render :layout => !request.xhr?
      }
      format.api  {
        @issues = WbsQuery.new(@project).issues
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

  def build_default_tracker_id
    allowed_tracker_ids = @project.tracker_ids

    if allowed_tracker_ids.include? RedmineWbs.default_tracker_id
      @default_tracker_id = RedmineWbs.default_tracker_id
      return
    end

    unless allowed_tracker_ids.any?
      render_error :message => l(:error_no_tracker_allowed_for_new_issue_in_project), :status => 403

      return false
    end

    @default_tracker_id = allowed_tracker_ids.first
  end
end
