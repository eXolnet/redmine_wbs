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

  private

  def query_issues
    WbsQuery.new(@project).issues.to_a
  end
end
