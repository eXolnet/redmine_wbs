class WbsController < ApplicationController
  default_search_scope :issues
  menu_item :wbs

  before_action :ensure_rest_api_is_available
  before_action :find_optional_project
  before_action :build_default_tracker_id
  before_action :build_excluded_tracker_ids
  accept_api_auth :index

  def index
    respond_to do |format|
      format.html {
        render :layout => !request.xhr?
      }
      format.api  {
        query = "
          SELECT I.*
            FROM issues I
           WHERE I.`project_id` = ?
             AND I.`root_id` NOT IN (
              SELECT I.`id`
                FROM `issues` I
                JOIN `trackers` T ON t.`id` = I.`tracker_id`
               WHERE I.`root_id` = I.`id` AND I.`tracker_id` IN (?) OR T.`fields_bits` & 64
            )
          ORDER BY I.`root_id` ASC, I.`lft` ASC
        "

        @issues = Issue.find_by_sql([query, @project.id, @excluded_tracker_ids])
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

  def build_excluded_tracker_ids
    @excluded_tracker_ids = RedmineWbs.excluded_tracker_ids.reject { |item| item.empty? }.join(',')
  end
end
