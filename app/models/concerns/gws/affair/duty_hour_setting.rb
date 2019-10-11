module Gws::Affair::DutyHourSetting
  extend ActiveSupport::Concern
  extend SS::Translation

  included do
    attr_accessor :in_attendance_time_change_hour

    field :attendance_time_changed_minute, type: Integer, default: 3 * 60

    field :affair_start_at_hour, type: Integer, default: 9
    field :affair_start_at_minute, type: Integer, default: 0
    field :affair_end_at_hour, type: Integer, default: 18
    field :affair_end_at_minute, type: Integer, default: 0

    field :affair_on_duty_working_minute, type: Integer
    field :affair_on_duty_break_minute, type: Integer
    field :affair_overtime_working_minute, type: Integer
    field :affair_overtime_break_minute, type: Integer

    permit_params :in_attendance_time_change_hour
    permit_params :affair_start_at_hour, :affair_start_at_minute, :affair_end_at_hour, :affair_end_at_minute
    permit_params :affair_on_duty_working_minute, :affair_on_duty_break_minute
    permit_params :affair_overtime_working_minute, :affair_overtime_break_minute

    before_validation :set_attendance_time_changed_minute

    validates :affair_start_at_hour, presence: true,
              numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 23 }
    validates :affair_start_at_minute, presence: true,
              numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 59 }
    validates :affair_end_at_hour, presence: true,
              numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 23 }
    validates :affair_end_at_minute, presence: true,
              numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 59 }
  end

  def affair_start_at_hour_options
    (0..23).map do |h|
      [ "#{h}#{I18n.t('datetime.prompts.hour')}", h.to_s ]
    end
  end

  def affair_end_at_hour_options
    (0..23).map do |h|
      [ "#{h}#{I18n.t('datetime.prompts.hour')}", h.to_s ]
    end
  end

  def attendance_time_changed_options
    (0..23).map do |h|
      [ "#{h}#{I18n.t('datetime.prompts.hour')}", h.to_s ]
    end
  end

  def affair_start_at_minute_options
    0.step(59, 5).map do |h|
      [ "#{h}#{I18n.t('datetime.prompts.minute')}", h.to_s ]
    end
  end

  def affair_end_at_minute_options
    0.step(59, 5).map do |h|
      [ "#{h}#{I18n.t('datetime.prompts.minute')}", h.to_s ]
    end
  end

  def calc_attendance_date(time = Time.zone.now)
    Time.zone.at(time.to_i - attendance_time_changed_minute * 60).beginning_of_day
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
      allow(:read, user, site: site).
      search(start: date, end: date).present?
  end

  private

  def set_attendance_time_changed_minute
    if in_attendance_time_change_hour.blank?
      self.attendance_time_changed_minute = 3 * 60
    else
      self.attendance_time_changed_minute = Integer(in_attendance_time_change_hour) * 60
    end
  end
end
