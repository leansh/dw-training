class GuideImportsController < ApplicationController
  include NestedInGuide

  skip_before_filter :verify_authenticity_token

  respond_to :json, :html

  def create
    @import = @guide.imports.create!(committer: @guide.author) #FIXME use current user
    flash[:notice] = t(:import_created)
    respond_with @import, location: edit_guide_path(@guide)
  end

  def index
    @imports = paginated @guide.imports
  end
end
