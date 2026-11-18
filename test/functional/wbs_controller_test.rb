require File.expand_path('../../test_helper', __FILE__)

class WbsControllerTest < Redmine::ControllerTest
  fixtures :projects,
           :users,
           :email_addresses,
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
    # Configure the logged user
    @request.session[:user_id] = 1

    # Enable the WBS module on one project
    @project1 = Project.find(1)
    EnabledModule.create(:project => @project1, :name => 'wbs')
  end

  def test_get_index_with_project
    get_index :project_id => 'ecookbook'

    assert_response :success
    assert_select 'h2', :text => 'WBS'
    assert_select 'form#wbs-list wbs-issues[project-id="1"]'
  end

  def test_get_index_with_project_as_json
    @request.session[:user_id] = nil
    @request.headers['X-Redmine-API-Key'] = User.find(1).api_key

    get_index :project_id => 'ecookbook', :format => 'json'

    assert_response :success
    assert_equal Project.find(1).issues.count, JSON.parse(response.body)['total_count']
  end

  def test_get_index_renders_wbs_issues_element_attributes
    with_settings :plugin_redmine_wbs => { 'additional_columns' => ['status', 'assigned_to'] } do
      get_index :project_id => 'ecookbook'
    end

    assert_response :success
    element = css_select('wbs-issues').first
    assert_not_nil element
    assert_equal '1', element['project-id']
    assert_equal '1', element['default-tracker-id']
    assert_equal ['Status', 'Assignee'], JSON.parse(element[':additional-columns'])
    assert_select 'wbs-issues template th', :text => 'Status'
    assert_select 'wbs-issues template th', :text => 'Assignee'
  end

  def test_get_index_renders_user_api_key_meta_tag
    api_key = User.find(1).api_key

    get_index :project_id => 'ecookbook'

    assert_response :success
    assert_select 'meta[name="user-api-key"][content=?]', api_key
  end

  def test_get_index_without_api_token_does_not_render_user_api_key_meta_tag
    Token.where(:user_id => 1, :action => 'api').delete_all

    get_index :project_id => 'ecookbook'

    assert_response :success
    assert_select 'meta[name="user-api-key"]', 0
  end

  def test_get_index_with_xhr_renders_without_layout
    get_index({ :project_id => 'ecookbook' }, :xhr => true)

    assert_response :success
    assert_select 'wbs-issues[project-id="1"]'
    assert_select '#header', 0
    assert_select '#main-menu', 0
  end

  def test_get_index_as_member_with_view_wbs_permission
    Role.find(1).add_permission! :view_wbs
    @request.session[:user_id] = 2

    get_index :project_id => 'ecookbook'

    assert_response :success
    assert_select 'wbs-issues[project-id="1"]'
  end

  def test_get_index_as_member_without_view_wbs_permission
    Role.find(1).remove_permission! :view_wbs
    @request.session[:user_id] = 2

    get_index :project_id => 'ecookbook'

    assert_response :forbidden
  end

  def test_get_index_as_non_member_of_private_project
    Role.non_member.add_permission! :view_wbs
    EnabledModule.create(:project => Project.find(2), :name => 'wbs')
    @request.session[:user_id] = 3

    get_index :project_id => 'onlinestore'

    assert_response :forbidden
  end

  def test_get_index_with_module_disabled
    Role.find(1).add_permission! :view_wbs
    @request.session[:user_id] = 2

    get_index :project_id => 'onlinestore'

    assert_response :forbidden
  end

  def test_get_index_as_anonymous_redirects_to_login
    @request.session[:user_id] = nil

    get_index :project_id => 'ecookbook'

    assert_response :redirect
    assert_match %r{/login\?back_url=}, response.location
  end

  def test_get_index_as_anonymous_with_api_format
    @request.session[:user_id] = nil

    get_index :project_id => 'ecookbook', :format => 'json'

    assert_response :unauthorized
  end

  def test_get_index_with_unknown_project
    get_index :project_id => 'unknown'

    assert_response :not_found
  end

  def test_get_index_with_rest_api_disabled
    with_settings :rest_api_enabled => '0' do
      get :index, :params => { :project_id => 'ecookbook' }
    end

    assert_response :forbidden
    assert_select 'p#errorExplanation', :text => /REST API is required/
  end

  def test_get_index_uses_configured_default_tracker
    with_settings :plugin_redmine_wbs => { 'default_tracker' => '2' } do
      get_index :project_id => 'ecookbook'
    end

    assert_response :success
    assert_select 'wbs-issues[default-tracker-id="2"]'
  end

  def test_get_index_ignores_configured_default_tracker_not_allowed_in_project
    @project1.trackers.delete(Tracker.find(3))

    with_settings :plugin_redmine_wbs => { 'default_tracker' => '3' } do
      get_index :project_id => 'ecookbook'
    end

    assert_response :success
    assert_select 'wbs-issues[default-tracker-id=?]', @project1.tracker_ids.first.to_s
    assert_not_equal 3, @project1.tracker_ids.first
  end

  def test_get_index_with_project_without_trackers
    @project1.trackers.clear

    get_index :project_id => 'ecookbook'

    assert_response :forbidden
    assert_select 'p#errorExplanation', :text => /doesn't have any trackers/
  end

  def test_get_index_as_xml
    @request.session[:user_id] = nil
    @request.headers['X-Redmine-API-Key'] = User.find(1).api_key

    get_index :project_id => 'ecookbook', :format => 'xml'

    assert_response :success
    assert_equal 'application/xml', response.media_type
    assert_select 'issues[type=array][total_count=?]', WbsQuery.new(@project1).issue_count.to_s
    assert_select 'issues > issue > id', :text => '1'
    assert_select 'issues > issue > additionnal_columns[type=array]'
  end

  def test_get_index_as_json_renders_404_when_a_record_is_not_found
    WbsQuery.any_instance.stubs(:issues).raises(ActiveRecord::RecordNotFound)
    @request.session[:user_id] = nil
    @request.headers['X-Redmine-API-Key'] = User.find(1).api_key

    get_index :project_id => 'ecookbook', :format => 'json'

    assert_response :not_found
  end

  def test_get_index_as_json_returns_tree_levels_and_parents
    root = child = grandchild = sibling = nil
    with_settings :notified_events => [] do
      root = Issue.generate!(:project => @project1, :tracker_id => 1, :subject => 'WBS root')
      child = Issue.generate!(:project => @project1, :tracker_id => 1, :parent_issue_id => root.id)
      grandchild = Issue.generate!(:project => @project1, :tracker_id => 1, :parent_issue_id => child.id)
      sibling = Issue.generate!(:project => @project1, :tracker_id => 1, :parent_issue_id => root.id)
    end

    items = get_json_issues

    assert_equal [0, nil], items[root.id].values_at('level', 'parent_id')
    assert_equal [1, root.id], items[child.id].values_at('level', 'parent_id')
    assert_equal [2, child.id], items[grandchild.id].values_at('level', 'parent_id')
    assert_equal [1, root.id], items[sibling.id].values_at('level', 'parent_id')
    assert_equal root.id, items[grandchild.id]['root_id']
    assert_equal 'WBS root', items[root.id]['subject']
  end

  def test_get_index_as_json_returns_additional_columns
    items = nil
    with_settings :plugin_redmine_wbs => { 'additional_columns' => ['status', 'priority'] } do
      items = get_json_issues
    end

    columns = items[1]['additionnal_columns']
    assert_equal ['status', 'priority'], columns.map { |column| column['name'] }
    assert_equal Issue.find(1).status.name, columns[0]['content']
    assert_equal Issue.find(1).priority.name, columns[1]['content']
    assert_equal 'status', columns[0]['css_classes']
  end

  def test_get_index_as_json_without_additional_columns
    items = get_json_issues

    assert_equal [], items[1]['additionnal_columns']
  end

  private

  def get_index(params, options = {})
    with_settings :rest_api_enabled => '1' do
      get :index, **options.merge(:params => params)
    end
  end

  def get_json_issues
    @request.session[:user_id] = nil
    @request.headers['X-Redmine-API-Key'] = User.find(1).api_key

    get_index :project_id => 'ecookbook', :format => 'json'
    assert_response :success

    JSON.parse(response.body)['issues'].index_by { |issue| issue['id'] }
  end
end
