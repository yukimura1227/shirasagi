module Gws::Addon::User::DutyHour
  extend ActiveSupport::Concern
  extend SS::Addon

  def effective_duty_calendar(site)
    duty_calendar = Gws::Affair::DutyCalendar.site(site).in(member_ids: id).order_by(id: 1).first
    return duty_calendar if duty_calendar.present?

    main_group = gws_main_group(site)
    if main_group.present?
      duty_calendar = Gws::Affair::DutyCalendar.site(site).in(member_group_ids: main_group.id).order_by(id: 1).first
    end
    return duty_calendar if duty_calendar.present?

    Gws::Affair::DefaultDutyCalendar.new(cur_site: site, cur_user: self)
  end
end
