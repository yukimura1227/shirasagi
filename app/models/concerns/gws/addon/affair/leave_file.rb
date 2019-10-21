module Gws::Addon::Affair::LeaveFile
  extend ActiveSupport::Concern
  extend SS::Addon

  included do
    attr_accessor :start_at_date, :start_at_hour, :start_at_minute
    attr_accessor :end_at_hour, :end_at_minute

    field :date, type: DateTime
    field :start_at, type: DateTime
    field :end_at, type: DateTime

    field :leave_type, type: String
    field :reason, type: String
    belongs_to :week_in_compensatory_file, class_name: "Gws::Affair::OvertimeFile"
    belongs_to :week_out_compensatory_file, class_name: "Gws::Affair::OvertimeFile"

    permit_params :start_at_date, :start_at_hour, :start_at_minute
    permit_params :end_at_hour, :end_at_minute

    permit_params :leave_type
    permit_params :reason
    permit_params :week_in_compensatory_file_id
    permit_params :week_out_compensatory_file_id

    before_validation :validate_date
    before_validation :compensatory_file

    validates :leave_type, presence: true
    validates :start_at, presence: true, datetime: true
    validates :end_at, datetime: true

    validates :week_in_compensatory_file_id, presence: true, if: ->{ leave_type == "week_in_compensatory_leave" }
    validates :week_out_compensatory_file_id, presence: true, if: ->{ leave_type == "week_out_compensatory_leave" }

    validate :validate_week_in_compensatory_file, if: ->{ week_in_compensatory_file }
    validate :validate_week_out_compensatory_file, if: ->{ week_out_compensatory_file }

    after_initialize do
      self.start_at_date = start_at.strftime("%Y/%m/%d") if start_at
      self.start_at_hour = start_at.hour if start_at
      self.start_at_minute = start_at.minute if start_at
      self.end_at_hour = end_at.hour if end_at
      self.end_at_minute = end_at.minute if end_at
    end
  end

  def start_at_hour_options
    (0..23).map { |h| [ "#{h}#{I18n.t('datetime.prompts.hour')}", h.to_s ] }
  end

  def start_at_minute_options
    (0..59).select { |m| m % 5 == 0 }.map { |m| [ "#{m}#{I18n.t('datetime.prompts.minute')}", m.to_s ] }
  end

  def end_at_hour_options
    (0..23).map { |h| [ "#{h}#{I18n.t('datetime.prompts.hour')}", h.to_s ] }
  end

  def end_at_minute_options
    (0..59).select { |m| m % 5 == 0 }.map { |m| [ "#{m}#{I18n.t('datetime.prompts.minute')}", m.to_s ] }
  end

  def leave_type_options
    I18n.t("gws/affair.options.leave_type").map { |k, v| [v, k] }
  end

  def validate_date
    return if start_at_date.blank? || start_at_hour.blank? || start_at_minute.blank?
    return if end_at_hour.blank? || end_at_minute.blank?

    site = cur_site || self.site
    user = cur_user || self.user
    return if site.blank?
    return if user.blank?

    self.start_at = Time.zone.parse("#{start_at_date} #{start_at_hour}:#{start_at_minute}")
    self.end_at = Time.zone.parse("#{start_at_date} #{end_at_hour}:#{end_at_minute}")
    self.end_at += 1.day if self.end_at < self.start_at

    if start_at >= end_at
      errors.add :end_at, :greater_than, count: t(:start_at)
    end

    duty_calendar = user.effective_duty_calendar(site)

    changed_at = duty_calendar.affair_next_changed(start_at)
    self.date = changed_at.advance(days: -1).change(hour: 0, min: 0, sec: 0)
  end

  def compensatory_file
    if leave_type != "week_in_compensatory_leave"
      self.week_in_compensatory_file_id = nil
    end

    if leave_type != "week_out_compensatory_leave"
      self.week_out_compensatory_file_id = nil
    end
  end

  def validate_week_in_compensatory_file
    if week_in_compensatory_file.workflow_state != "approve"
      errors.add :week_in_compensatory_file_id, "は承認されていません。"
      return
    end

    file_ids = self.class.where(workflow_state: "approve", :id.ne => id).
      pluck(:week_in_compensatory_file_id).compact

    if file_ids.include?(week_in_compensatory_file_id)
      errors.add :week_in_compensatory_file_id, "は他の休暇申請に設定されています。"
    end
  end

  def validate_week_out_compensatory_file
    if week_out_compensatory_file.workflow_state != "approve"
      errors.add :week_out_compensatory_file_id, "は承認されていません。"
      return
    end

    file_ids = self.class.where(workflow_state: "approve", :id.ne => id).
      pluck(:week_out_compensatory_file_id).compact

    if file_ids.include?(week_out_compensatory_file_id)
      errors.add :week_out_compensatory_file_id, "は他の休暇申請に設定されています。"
    end
  end

  def start_end_term
    return if start_at.blank? || end_at.blank?

    hour = ((end_at - start_at) * 24).to_i
    start_time = "#{start_at.hour}:#{format('%02d', start_at.minute)}"
    end_time = "#{start_at.hour + hour}:#{format('%02d', end_at.minute)}"
    "#{start_at.strftime("%Y/%m/%d")} #{start_time}#{I18n.t("ss.wave_dash")}#{end_time}"
  end

  def term_label
    name_label = user_name
    term_label = start_end_term
    return if name_label.blank? || term_label.blank?

    "#{name_label}の休暇申請（#{term_label}）"
  end
end
