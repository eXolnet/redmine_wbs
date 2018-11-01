module WbsHelper
  include IssuesHelper
  include QueriesHelper

  def column_value_with_wbs(column, item, value)
    if [:subject].include? column.name
      return tag('input', type: 'text', :value => value)
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
