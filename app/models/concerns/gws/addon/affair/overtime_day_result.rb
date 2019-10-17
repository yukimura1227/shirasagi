module Gws::Addon::Affair::OvertimeDayResult
  extend ActiveSupport::Concern
  extend SS::Addon

  included do
    has_many :day_results, class_name: 'Gws::Affair::OvertimeDayResult', dependent: :destroy, inverse_of: :file
    after_save :save_day_results
  end

  def save_day_results
    return if result.blank?

    duty_calendar = user.effective_duty_calendar(site)

    results = [[result.date, result.start_at, result.end_at]]

    # 日替わり時刻を超えているか
    changed_at = duty_calendar.affair_next_changed(result.start_at)
    if result.end_at > changed_at
      r_date = changed_at.change(hour: 0, min: 0, sec: 0)
      results = [
        [r_date.advance(days: -1), result.start_at, changed_at],
        [r_date, changed_at, result.end_at]
      ]
    end

    # 休憩時間
    break_time_subtractor = Gws::Affair::Subtractor.new(result.break_time_minute)

    # 振替時間
    week_in_subtractor = Gws::Affair::Subtractor.new(week_in_compensatory_minute)
    week_out_subtractor = Gws::Affair::Subtractor.new(week_out_compensatory_minute)

    # 日替わり時刻を超えているものがあるかもしれないので、全削除
    day_results.destroy_all

    results.each do |r_date, r_start_at, r_end_at|
      overtime_minute = ((r_end_at - r_start_at) * 24 * 60).to_i

      night_time_start = duty_calendar.night_time_start(r_date.to_datetime).to_datetime
      night_time_end = duty_calendar.night_time_end(r_date.to_datetime).to_datetime

      # 通常 深夜 休日通常 休日深夜
      if r_start_at >= night_time_start && r_end_at <= night_time_end
        day_time_minute = 0
        night_time_minute = overtime_minute
      elsif r_start_at >= night_time_end
        day_time_minute = overtime_minute
        night_time_minute = 0
      elsif r_start_at > night_time_start
        day_time_minute = ((r_end_at - night_time_end) * 24 * 60).to_i
        night_time_minute = ((night_time_end - r_start_at) * 24 * 60).to_i
      elsif r_end_at > night_time_start
        day_time_minute = ((night_time_start - r_start_at) * 24 * 60).to_i
        night_time_minute = ((r_end_at - night_time_start) * 24 * 60).to_i
      else #r_end_at <= night_time_start
        day_time_minute = overtime_minute
        night_time_minute = 0
      end

      is_holiday = duty_calendar.holiday?(r_date)
      if is_holiday
        duty_day_time_minute = 0
        duty_night_time_minute = 0

        leave_day_time_minute = day_time_minute
        leave_night_time_minute = night_time_minute
      else
        duty_day_time_minute = day_time_minute
        duty_night_time_minute = night_time_minute

        leave_day_time_minute = 0
        leave_night_time_minute = 0
      end

      # 休憩時間
      if break_time_subtractor.threshold > 0
        threshold = break_time_subtractor.threshold

        _, subtracted = break_time_subtractor.subtract(
          duty_day_time_minute,
          duty_night_time_minute,
          leave_day_time_minute,
          leave_night_time_minute
        )
        duty_day_time_minute = subtracted[0]
        duty_night_time_minute = subtracted[1]
        leave_day_time_minute = subtracted[2]
        leave_night_time_minute = subtracted[3]

        break_time_minute = threshold - break_time_subtractor.threshold
      else
        break_time_minute = 0
      end

      # 振替時間
      if week_in_subtractor.threshold > 0
        threshold = week_in_subtractor.threshold

        _, subtracted = week_in_subtractor.subtract(
          duty_day_time_minute,
          duty_night_time_minute,
          leave_day_time_minute,
          leave_night_time_minute
        )
        duty_day_time_minute = subtracted[0]
        duty_night_time_minute = subtracted[1]
        leave_day_time_minute = subtracted[2]
        leave_night_time_minute = subtracted[3]

        week_in_compensatory_minute = threshold - week_in_subtractor.threshold
      else
        week_in_compensatory_minute = 0
      end

      if week_out_subtractor.threshold > 0
        threshold = week_out_subtractor.threshold

        _, subtracted = week_out_subtractor.subtract(
          duty_day_time_minute,
          duty_night_time_minute,
          leave_day_time_minute,
          leave_night_time_minute
        )
        duty_day_time_minute = subtracted[0]
        duty_night_time_minute = subtracted[1]
        leave_day_time_minute = subtracted[2]
        leave_night_time_minute = subtracted[3]

        week_out_compensatory_minute = threshold - week_out_subtractor.threshold
      else
        week_out_compensatory_minute = 0
      end

      overtime_minute = duty_day_time_minute + duty_night_time_minute + leave_day_time_minute + leave_night_time_minute
      cond = {
        site_id: site.id,
        user_id: user.id,
        date: r_date,
        file_id: id
      }
      item = Gws::Affair::OvertimeDayResult.find_or_initialize_by(cond)
      item.overtime_minute = overtime_minute

      item.start_at = r_start_at
      item.end_at = r_end_at
      item.capital_id = capital_id

      item.is_holiday = is_holiday
      item.duty_day_time_minute = duty_day_time_minute
      item.duty_night_time_minute = duty_night_time_minute
      item.leave_day_time_minute = leave_day_time_minute
      item.leave_night_time_minute = leave_night_time_minute

      item.break_time_minute = break_time_minute

      item.week_in_compensatory_minute = week_in_compensatory_minute
      item.week_out_compensatory_minute = week_out_compensatory_minute

      item.save
    end
  end
end
