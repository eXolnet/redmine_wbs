require 'redmine'

WBS_VERSION_NUMBER = '1.1.0'

Redmine::Plugin.register :redmine_wbs do
  name 'WBS'
  author 'eXolnet'
  description 'Display a WBS view of a project’s issues.'
  version WBS_VERSION_NUMBER
  url 'https://github.com/eXolnet/redmine-wbs'
  author_url 'https://www.exolnet.com'

  requires_redmine :version_or_higher => '3.4'

  settings :default => {},
           :partial => 'settings/wbs/general'

  menu :project_menu, :wbs, { :controller => 'wbs', :action => 'index' }, :caption => :label_wbs, :before => :gantt, :param => :project_id

  project_module :wbs do
    permission :view_wbs, { :wbs => [:index] }
  end
end

require 'redmine_wbs'
