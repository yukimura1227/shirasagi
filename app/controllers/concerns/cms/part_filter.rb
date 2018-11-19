module Cms::PartFilter
  extend ActiveSupport::Concern
  include Cms::NodeFilter

  included do
    before_action :set_tree_navi, only: [:index]
  end

  private

  def redirect_url
    nil
  end
end
