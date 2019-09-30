module Gws::Addon::Affair
  module Approver
    extend ActiveSupport::Concern
    extend SS::Addon
    include Workflow::Approver
  end
end
