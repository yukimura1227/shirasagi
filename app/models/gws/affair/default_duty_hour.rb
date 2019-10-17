class Gws::Affair::DefaultDutyHour
  include ActiveModel::Model
  include Gws::SitePermission

  set_permission_name "gws_affair_duty_hours"

  def self.wrap(site)
    new(site)
  end

  attr_reader :site
  attr_accessor :cur_site

  def initialize(site)
    @site = site
  end

  def new_record?
    false
  end

  def persisted?
    true
  end

  def destroyed?
    false
  end

  def id
    "default"
  end

  def name
    I18n.t("gws/affair.default_duty_hour")
  end

  def addons
    []
  end

  def lookup_addons
  end

  def method_missing(name, *args, &block)
    if site.respond_to?(name)
      return site.send(name, *args, &block)
    end

    super
  end

  def respond_to_missing?(name, include_private)
    return true if site.respond_to?(name, include_private)

    super
  end

  def affair_start(time)
    time.change(hour: affair_start_at_hour, min: affair_start_at_minute, sec: 0)
  end

  def affair_end(time)
    time.change(hour: affair_end_at_hour, min: affair_end_at_minute, sec: 0)
  end

  def affair_next_changed(time)
    hour = attendance_time_changed_minute / 60
    changed = time.change(hour: hour, min: 0, sec: 0)
    (time > changed) ? changed.advance(days: 1) : changed
  end

  def night_time_start(time)
    hour = SS.config.gws.affair.dig("overtime", "night_time", "start_hour")
    time.change(hour: 0, min: 0, sec: 0).advance(hours: hour)
  end

  def night_time_end(time)
    hour = SS.config.gws.affair.dig("overtime", "night_time", "end_hour")
    time.change(hour: 0, min: 0, sec: 0).advance(hours: hour)
  end

  def leave_day?(date)
    date = date.to_datetime
    return true if (date.wday == 0 || date.wday == 6)

    # Gws::Attendance::TimeCardFilter
    return true if HolidayJapan.check(date.localtime.to_date)

    Gws::Schedule::Holiday.site(site).
      and_public.
      allow(:read, cur_user, site: site).
      search(start: date, end: date).present?
  end

  def holiday?(date)
    date = date.to_datetime
    #return true if (date.wday == 0 || date.wday == 6)

    # Gws::Attendance::TimeCardFilter
    return true if HolidayJapan.check(date.localtime.to_date)

    Gws::Schedule::Holiday.site(site).
      and_public.
      allow(:read, cur_user, site: site).
      search(start: date, end: date).present?
  end
end
