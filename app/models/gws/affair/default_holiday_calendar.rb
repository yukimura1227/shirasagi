class Gws::Affair::DefaultHolidayCalendar
  include ActiveModel::Model

  attr_accessor :cur_site

  def name
    I18n.t("gws/affair.options.holiday_type.system")
  end

  def leave_day?(date)
    date = date.to_datetime
    return true if date.wday == 0 || date.wday == 6

    holiday?(date)
  end

  def holiday?(date)
    return true if HolidayJapan.check(date.localtime.to_date)

    Gws::Schedule::Holiday.site(cur_site).
      and_public.
      and_system.
      search(start: date, end: date).present?
  end
end
