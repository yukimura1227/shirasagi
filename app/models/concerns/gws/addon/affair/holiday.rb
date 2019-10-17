module Gws::Addon::Affair::Holiday
  extend ActiveSupport::Concern
  extend SS::Addon

  included do
    field :holiday_type, type: String
    embeds_ids :holiday_calendars, class_name: 'Gws::Affair::HolidayCalendar'

    permit_params :holiday_type, holiday_calendar_ids: []

    validates :holiday_type, presence: true, inclusion: { in: %w(system own), allow_blank: true }
  end

  def holiday_type_options
    %w(system own).map do |v|
      [ I18n.t("gws/affair.options.holiday_type.#{v}"), v ]
    end
  end

  def holiday_type_system?
    !holiday_type_own?
  end

  def holiday_type_own?
    holiday_type == "own"
  end

  def holiday?(user, date)
    if holiday_type_system?
      return Gws::Affair::DefaultDutyHour.holiday?(@cur_site || site, user, date)
    end

    calendar = holiday_calendars.first
    return false if calendar.blank?

    calendar.holiday?(date)
  end
end
