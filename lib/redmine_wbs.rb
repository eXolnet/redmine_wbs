module RedmineWbs
  class << self
    def default_tracker_id
      Setting.plugin_redmine_wbs['default_tracker'].to_i
      end

    def excluded_tracker_ids
      Setting.plugin_redmine_wbs['excluded_tracker'] || []
    end

    def required_core_field_bits
      64 # is for 2^6 which is corresponding to "Estimated time" in trackers settings
    end
  end
end
