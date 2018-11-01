class WbsController < ApplicationController
  default_search_scope :issues
  menu_item :wbs

  before_action :find_optional_project

  rescue_from Query::StatementInvalid, :with => :query_statement_invalid

  include WbsHelper

  def index
    retrieve_query(WbsQuery)

    if @query.valid?
      @issues = @query.issues
    end

    render :layout => !request.xhr?
  rescue ActiveRecord::RecordNotFound
    render_404
  end
end
