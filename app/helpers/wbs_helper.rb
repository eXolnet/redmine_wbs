module WbsHelper
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
end
