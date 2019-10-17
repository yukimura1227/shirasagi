module Gws::Addon::Affair::DutyHour
  extend ActiveSupport::Concern
  extend SS::Addon

  included do
    embeds_ids :duty_hours, class_name: 'Gws::Affair::DutyHour'
    permit_params duty_hour_ids: []
  end
end
