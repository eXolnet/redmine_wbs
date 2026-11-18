require File.expand_path('../../test_helper', __FILE__)

class WbsQueryTest < ActiveSupport::TestCase
  fixtures :projects,
           :users,
           :email_addresses,
           :roles,
           :members,
           :member_roles,
           :issue_statuses,
           :trackers,
           :projects_trackers,
           :enabled_modules,
           :enumerations

  def setup
    User.current = User.find(1)
    @project = Project.find(1)
  end

  def teardown
    User.current = nil
  end

  def test_issues_includes_estimable_issues
    issue = Issue.generate!(:project => @project, :tracker_id => 1)

    assert_include issue, query_issues
  end

  def test_issues_excludes_trackers_without_estimated_time
    Tracker.find(2).update_column(:fields_bits, RedmineWbs.required_core_field_bits)
    included = Issue.generate!(:project => @project, :tracker_id => 1)
    excluded = Issue.generate!(:project => @project, :tracker_id => 2)

    issues = query_issues

    assert_include included, issues
    assert_not_include excluded, issues
  end

  def test_issues_excludes_configured_trackers
    included = Issue.generate!(:project => @project, :tracker_id => 1)
    excluded = Issue.generate!(:project => @project, :tracker_id => 2)

    with_settings :plugin_redmine_wbs => { 'excluded_trackers' => ['2'] } do
      issues = query_issues

      assert_include included, issues
      assert_not_include excluded, issues
    end
  end

  def test_issues_excludes_descendants_of_issues_with_configured_statuses
    included = Issue.generate!(:project => @project, :tracker_id => 1)
    parent = Issue.generate!(:project => @project, :tracker_id => 1, :status_id => 3)
    child = Issue.generate!(:project => @project, :tracker_id => 1, :parent_issue_id => parent.id)

    with_settings :plugin_redmine_wbs => { 'excluded_statuses' => ['3'] } do
      issues = query_issues

      assert_include included, issues
      assert_not_include parent, issues
      assert_not_include child, issues
    end
  end

  def test_issues_are_ordered_by_root_and_lft
    first_root = Issue.generate!(:project => @project, :tracker_id => 1)
    second_root = Issue.generate!(:project => @project, :tracker_id => 1)
    first_child = Issue.generate!(:project => @project, :tracker_id => 1, :parent_issue_id => first_root.id)
    second_child = Issue.generate!(:project => @project, :tracker_id => 1, :parent_issue_id => second_root.id)
    nested_child = Issue.generate!(:project => @project, :tracker_id => 1, :parent_issue_id => first_child.id)

    ids = [first_root, second_root, first_child, second_child, nested_child].map(&:id)

    assert_equal [first_root.id, first_child.id, nested_child.id, second_root.id, second_child.id],
                 query_issues.map(&:id) & ids
  end

  def test_issues_hides_issues_not_visible_to_the_current_user
    visible = Issue.generate!(:project => @project, :tracker_id => 1)
    private_issue = Issue.generate!(:project => @project, :tracker_id => 1, :is_private => true, :author => User.find(1))

    User.current = User.find(3)
    issues = query_issues

    assert_include visible, issues
    assert_not_include private_issue, issues
  end

  def test_issues_excludes_issues_of_other_projects
    included = Issue.generate!(:project => @project, :tracker_id => 1)
    other = Issue.generate!(:project => Project.find(2), :tracker_id => 1)

    issues = query_issues

    assert_include included, issues
    assert_not_include other, issues
  end

  def test_issues_excludes_descendants_of_issues_with_excluded_trackers
    included = Issue.generate!(:project => @project, :tracker_id => 1)
    parent = Issue.generate!(:project => @project, :tracker_id => 2)
    child = Issue.generate!(:project => @project, :tracker_id => 1, :parent_issue_id => parent.id)
    grandchild = Issue.generate!(:project => @project, :tracker_id => 1, :parent_issue_id => child.id)

    with_settings :plugin_redmine_wbs => { 'excluded_trackers' => ['2'] } do
      issues = query_issues

      assert_include included, issues
      assert_not_include parent, issues
      assert_not_include child, issues
      assert_not_include grandchild, issues
    end
  end

  def test_issues_keeps_ancestors_of_excluded_issues
    parent = Issue.generate!(:project => @project, :tracker_id => 1)
    excluded = Issue.generate!(:project => @project, :tracker_id => 2, :parent_issue_id => parent.id)

    with_settings :plugin_redmine_wbs => { 'excluded_trackers' => ['2'] } do
      issues = query_issues

      assert_include parent.reload, issues
      assert_not_include excluded, issues
    end
  end

  def test_issue_count
    Issue.generate!(:project => @project, :tracker_id => 1)
    query = WbsQuery.new(@project)

    assert_equal query.issues.to_a.size, query.issue_count
    assert query.issue_count > 0
  end

  def test_issue_count_does_not_count_excluded_issues
    with_settings :plugin_redmine_wbs => { 'excluded_trackers' => ['2'] } do
      count = WbsQuery.new(@project).issue_count

      Issue.generate!(:project => @project, :tracker_id => 2)
      assert_equal count, WbsQuery.new(@project).issue_count

      Issue.generate!(:project => @project, :tracker_id => 1)
      assert_equal count + 1, WbsQuery.new(@project).issue_count
    end
  end

  private

  def query_issues
    WbsQuery.new(@project).issues.to_a
  end
end
