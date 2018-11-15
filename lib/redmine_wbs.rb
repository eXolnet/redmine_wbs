module RedmineWbs
  class << self
    def default_tracker_id
      Setting.plugin_redmine_wbs['default_tracker'].to_i
      end

    def excluded_tracker_ids
      Setting.plugin_redmine_wbs['excluded_tracker'] || []
    end
  end
end
