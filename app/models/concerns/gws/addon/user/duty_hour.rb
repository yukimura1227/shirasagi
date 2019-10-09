module Gws::Addon::User::DutyHour
  extend ActiveSupport::Concern
  extend SS::Addon

  def effective_duty_hour(site)
    duty_hour = Gws::Affair::DutyHour.site(site).in(member_ids: id).order_by(id: 1).first
    return duty_hour if duty_hour.present?

    main_group = gws_main_group(site)
    if main_group.present?
      duty_hour = Gws::Affair::DutyHour.site(site).in(member_group_ids: main_group.id).order_by(id: 1).first
    end
    return duty_hour if duty_hour.present?

    Gws::Affair::DefaultDutyHour.wrap(site)
  end
end
