module Gws::Reference::Affair::DutyHour
  extend ActiveSupport::Concern

  included do
    belongs_to :duty_hour, class_name: "Gws::Affair::DutyHour"

    scope :and_system, -> { exists(duty_hour_id: false) }
    scope :and_duty_hour, ->(duty_hour) { where(duty_hour_id: duty_hour.id) }
  end
end
