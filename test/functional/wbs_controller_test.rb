require File.expand_path('../../test_helper', __FILE__)

class WbsControllerTest < ActionController::TestCase
  fixtures :projects,
           :users,
           :roles,
           :members,
           :member_roles,
           :enabled_modules,
           :enumerations,
           :repositories,
           :changesets,
           :changes

  def setup
    @project1 = Project.find(1)
    @project2 = Project.find(5)
    EnabledModule.create(:project => @project1, :name => 'wbs')
    EnabledModule.create(:project => @project2, :name => 'wbs')
    @request.session[:user_id] = 1
  end

  def test_get_index_with_project
    get :index, :project_id => 'ecookbook'

    assert_response :success
  end
end
