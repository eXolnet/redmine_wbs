module WbsHelper
  def wbs_column_footer(query, column, options={})
    if column.name == :estimated_hours
      content = "0.00"
    elsif column.name == :spent_hours
      content = "0.00"
    else
      content = " "
    end

    content_tag('td', content)
  end
end
