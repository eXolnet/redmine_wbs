module RedmineWbs
  class << self
    BASE_COLUMNS = %w(subject description estimated_hours total_estimated_hours)

    def default_tracker_id
      Setting.plugin_redmine_wbs['default_tracker'].to_i
      end

    def excluded_tracker_ids
      Setting.plugin_redmine_wbs['excluded_tracker'] || []
    end

    def additional_columns_available
      IssueQuery.new.available_inline_columns
        .reject(&:frozen?)
        .reject { |column| BASE_COLUMNS.include?(column.name.to_s) }
    end

    def additional_column_ids
      Setting.plugin_redmine_wbs['additional_columns'] || []
    end

    def additional_columns
      columns = self.additional_columns_available.inject({}) do |hash, column|
        hash[column.name.to_s] = column
        hash
      end

      self.additional_column_ids.map { |column| columns[column] }
    end

    def required_core_field_bits
      64 # is for 2^6 which is corresponding to "Estimated time" in trackers settings
    end
  end
end
