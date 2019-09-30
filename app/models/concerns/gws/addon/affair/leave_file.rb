module Gws::Addon::Affair::LeaveFile
  extend ActiveSupport::Concern
  extend SS::Addon

  included do
    field :start_at, type: DateTime
    field :end_at, type: DateTime
    field :leave_type, type: String
    field :reason, type: String

    permit_params :start_at
    permit_params :end_at
    permit_params :leave_type
    permit_params :reason

    validates :leave_type, presence: true
    validates :start_at, presence: true, datetime: true
    validates :end_at, presence: true, datetime: true
  end

  def leave_type_options
    I18n.t("gws/affair.options.leave_type").map { |k, v| [v, k] }
  end
end
