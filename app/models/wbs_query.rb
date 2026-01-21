class WbsQuery
  def initialize(project)
    @project = project
  end

  def issues
    Issue
      .visible
      .where(project_id: @project.id)
      .where.not(id: excluded_issues)
      .order("#{Issue.table_name}.root_id ASC, #{Issue.table_name}.lft ASC")
  end

  def issue_count
    issues.count
  end

  private

  def excluded_issues
    subquery = Issue
      .visible
      .where(project_id: @project.id)
      .where(
        "#{Issue.table_name}.tracker_id IN (?) OR #{Issue.table_name}.status_id IN (?)",
        excluded_trackers,
        RedmineWbs.excluded_status_ids
      )

    Issue
      .select(:id)
      .visible
      .where(project_id: @project.id)
      .joins("INNER JOIN (#{subquery.to_sql}) parent on #{Issue.table_name}.root_id = parent.root_id")
      .where("#{Issue.table_name}.lft >= parent.lft")
      .where("#{Issue.table_name}.rgt <= parent.rgt")
  end

  # A tracker is excluded if it's manually excluded or it doesn't have the
  # field "Estimated Time" enabled
  def excluded_trackers
    Tracker.select(:id)
      .where(
        "#{Tracker.table_name}.id IN (?) OR (#{Tracker.table_name}.fields_bits & ?) != 0",
        RedmineWbs.excluded_tracker_ids,
        RedmineWbs.required_core_field_bits
      )
  end
end
