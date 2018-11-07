module WbsHelper
  include IssuesHelper
  include QueriesHelper

  def wbs_grouped_issue_list(issues, &block)
    ancestors = []

    issues.each do |issue|
      while (ancestors.any? && !issue.is_descendant_of?(ancestors.last))
        ancestors.pop
      end
      yield issue, ancestors.size
      ancestors << issue unless issue.leaf?
    end
  end

  def column_value_with_wbs(column, item, value)
    if [:subject].include? column.name
      return tag('input', type: 'text', ':value' => 'props.issue.subject', '@input' => 'props.update({"subject": $event.target.value})')
    end

    if [:estimated_hours].include? column.name
      return tag('input', type: 'number', ':value' => 'props.issue.estimated_hours', '@input' => 'props.update({"estimated_hours": $event.target.value})')
    end

    column_value_without_wbs(column, item, value)
  end

  def column_footer(query, column, options={})
    if column.name == :estimated_hours
      content = "0.00"
    elsif column.name == :spent_hours
      content = "0.00"
    else
      content = " "
    end

    content_tag('td', content)
  end

  alias_method_chain :column_value, :wbs
end
