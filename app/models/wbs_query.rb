class WbsQuery < IssueQuery
  self.available_columns = [
    QueryColumn.new(:id, :caption => '#', :frozen => true),
    QueryColumn.new(:subject, :frozen => true),
    QueryColumn.new(:tracker),
    QueryColumn.new(:status),
    QueryColumn.new(:priority),
    QueryColumn.new(:category),
    QueryColumn.new(:fixed_version),
    QueryColumn.new(:start_date),
    QueryColumn.new(:due_date),
    QueryColumn.new(:estimated_hours),
    #QueryColumn.new(:total_estimated_hours),
    QueryColumn.new(:done_ratio),
    QueryColumn.new(:description, :inline => false)
  ]

  def available_columns
    return @wbs_available_columns if @wbs_available_columns

    @wbs_available_columns = self.class.available_columns.dup

    if User.current.allowed_to?(:view_time_entries, project, :global => true)
      add_spent_time_columns
    end
  end

  def default_columns_names
    @default_columns_names = [:category, :estimated_hours]

    if User.current.allowed_to?(:view_time_entries, project, :global => true)
      @default_columns_names << :spent_hours
    end

    @default_columns_names
  end

  def sort_clause
    'IFNULL(issues.root_id, issues.id) ASC, issues.lft ASC'
  end

  private

  def add_spent_time_columns
    # insert the columns after total_estimated_hours or at the end
    index = @wbs_available_columns.find_index {|column| column.name == :total_estimated_hours}
    index = (index ? index + 1 : -1)

    @wbs_available_columns.insert index, QueryColumn.new(:spent_hours, :caption => :label_spent_time)
    #@wbs_available_columns.insert index+1, QueryColumn.new(:total_spent_hours, :caption => :label_total_spent_time)
  end
end
