require File.expand_path('../../test_helper', __FILE__)

class WbsControllerTest < ActionController::TestCase
  fixtures :projects,
           :users,
           :roles,
           :members,
           :member_roles,
           :issues,
           :issue_statuses,
           :trackers,
           :projects_trackers,
           :issue_categories,
           :enabled_modules,
           :enumerations

  def setup
    # Enable the REST API
    Setting.rest_api_enabled = 1

    # Configure the logged user
    @request.session[:user_id] = 1
    User.current.create_api_token

    # Enable the WBS module on one project
    @project1 = Project.find(1)
    EnabledModule.create(:project => @project1, :name => 'wbs')
  end

  def test_get_index_with_project
    compatible_request :get, :index, :project_id => 'ecookbook'

    assert_response :success
  end

  def test_get_index_with_project_as_json
    @request.session[:user_id] = nil
    @request.headers['X-Redmine-API-Key'] = User.find(1).api_key

    compatible_request :get, :index, :project_id => 'ecookbook', :format => 'json'

    assert_response :success
    assert_equal Project.find(1).issues.count, JSON.parse(response.body)['total_count']
  end
end
