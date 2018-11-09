module RedmineWbs
  class << self
    def default_tracker_id
      Setting.plugin_redmine_wbs['default_tracker'].to_i
    end
  end
end
