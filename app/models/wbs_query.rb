class WbsQuery
  def initialize(project)
    @project = project
  end

  def issues
    Issue
      .where(root_id: visible_root_issues)
      .order("#{Issue.table_name}.root_id ASC, #{Issue.table_name}.lft ASC")
  end

  def issue_count
    issues.count
  end

  private

  def visible_root_issues
    Issue
      .select(:id)
      .visible
      .where("#{Issue.table_name}.root_id = #{Issue.table_name}.id")
      .where(project_id: @project.id)
      .where.not(tracker_id: valid_trackers)
  end

  def valid_trackers
    Tracker.select(:id)
      .where(
        "#{Tracker.table_name}.id IN (?) OR #{Tracker.table_name}.fields_bits & ?",
        RedmineWbs.excluded_tracker_ids,
        RedmineWbs.required_core_field_bits
      )
  end
end
