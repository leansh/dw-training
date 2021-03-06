module WithPath
  extend ActiveSupport::Concern

  included do
    include WithSiblings

    belongs_to :path
  end

  def siblings_for(user)
    path.pending_guides(user)
  end

  def siblings
    path.guides
  end

  def parent
    path
  end
end
