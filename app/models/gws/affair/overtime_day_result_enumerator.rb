class Gws::Affair::OvertimeDayResultEnumerator < Enumerator

  def initialize(prefs, users, threshold, params)
    @prefs = prefs
    @threshold = threshold
    @users = users
    @params = params

    super() do |y|
      y << bom + encode(headers.to_csv)
      @users.each do |user|
        enum_record(y, user)
      end
    end
  end

  def headers
    line = []
    line << Gws::User.t(:name)
    line << Gws::User.t(:organization_uid)
    line << I18n.t("gws/affair.labels.overtime.#{@threshold}_threshold.duty_day_time.rate")
    line << I18n.t("gws/affair.labels.overtime.#{@threshold}_threshold.duty_night_time.rate")
    line << I18n.t("gws/affair.labels.overtime.#{@threshold}_threshold.leave_day_time.rate")
    line << I18n.t("gws/affair.labels.overtime.#{@threshold}_threshold.leave_night_time.rate")
    line << I18n.t("gws/affair.labels.overtime.#{@threshold}_threshold.week_out_compensatory.rate")
    line
  end

  private

  def enum_record(yielder, user)
    duty_day_time_minute = @prefs.dig(user.id, "#{@threshold}_threshold", "duty_day_time_minute")
    duty_night_time_minute = @prefs.dig(user.id, "#{@threshold}_threshold", "duty_night_time_minute")
    leave_day_time_minute = @prefs.dig(user.id, "#{@threshold}_threshold", "leave_day_time_minute")
    leave_night_time_minute = @prefs.dig(user.id, "#{@threshold}_threshold", "leave_night_time_minute")
    week_out_compensatory_minute = @prefs.dig(user.id, "#{@threshold}_threshold", "week_out_compensatory_minute")

    line = []
    line << user.long_name
    line << user.organization_uid
    line << format_minute(duty_day_time_minute)
    line << format_minute(duty_night_time_minute)
    line << format_minute(leave_day_time_minute)
    line << format_minute(leave_night_time_minute)
    line << format_minute(week_out_compensatory_minute)

    yielder << encode(line.to_csv)
  end

  def bom
    return '' if @params.encoding == 'Shift_JIS'
    "\uFEFF"
  end

  def encode(str)
    return '' if str.blank?

    str = str.encode('CP932', invalid: :replace, undef: :replace) if @params.encoding == 'Shift_JIS'
    str
  end

  def format_minute(minute)
    (minute.to_i > 0) ? "#{minute / 60}:#{format("%02d", (minute % 60))}" : ""
  end
end
