module Cms::Reference
  module Lang
    extend ActiveSupport::Concern
    extend SS::Translation

    included do
      field :lang_id, type: String
      permit_params :lang_id
    end
  end
end
