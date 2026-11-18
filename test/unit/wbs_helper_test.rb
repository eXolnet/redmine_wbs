require File.expand_path('../../test_helper', __FILE__)

class WbsHelperTest < Redmine::HelperTest
  include WbsHelper

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
    super
    @project = Project.find(1)
  end

  def test_wbs_grouped_issue_list_yields_levels_for_multi_level_tree
    with_settings :notified_events => [] do
      root = generate_issue
      child = generate_issue(root)
      grandchild = generate_issue(child)
      great_grandchild = generate_issue(grandchild)
      child_sibling = generate_issue(root)
      other_root = generate_issue

      assert_equal [
        [root.id, 0],
        [child.id, 1],
        [grandchild.id, 2],
        [great_grandchild.id, 3],
        [child_sibling.id, 1],
        [other_root.id, 0]
      ], grouped_levels([root, child, grandchild, great_grandchild, child_sibling, other_root])
    end
  end

  def test_wbs_grouped_issue_list_yields_same_level_for_siblings
    with_settings :notified_events => [] do
      root = generate_issue
      first = generate_issue(root)
      second = generate_issue(root)
      third = generate_issue(root)

      assert_equal [[root.id, 0], [first.id, 1], [second.id, 1], [third.id, 1]],
                   grouped_levels([root, first, second, third])
    end
  end

  def test_wbs_grouped_issue_list_yields_root_level_for_unrelated_issues
    with_settings :notified_events => [] do
      issues = 3.times.map { generate_issue }

      assert_equal issues.map { |issue| [issue.id, 0] }, grouped_levels(issues)
    end
  end

  def test_wbs_grouped_issue_list_with_no_issues_does_not_yield
    assert_equal [], grouped_levels([])
  end

  private

  def generate_issue(parent = nil)
    Issue.generate!(:project => @project, :tracker_id => 1, :parent_issue_id => parent.try(:id))
  end

  def grouped_levels(issues)
    ordered = Issue.where(:id => issues.map(&:id)).reorder(:root_id, :lft).to_a
    levels = []
    wbs_grouped_issue_list(ordered) { |issue, level| levels << [issue.id, level] }
    levels
  end
end
