module Gws::Addon::Attendance::GroupSetting
  extend ActiveSupport::Concern
  extend SS::Addon
  include Gws::Affair::DutyHourSetting

  set_addon_type :organization

  included do
    field :attendance_year_changed_month, type: Integer, default: 4
    field :attendance_management_year, type: Integer, default: 3
    field :attendance_enter_label, type: String
    field :attendance_leave_label, type: String
    SS.config.gws.attendance['max_break'].times do |i|
      field "attendance_break_time#{i + 1}_state", type: String
      field "attendance_break_enter#{i + 1}_label", type: String
      field "attendance_break_leave#{i + 1}_label", type: String
      alias_method("attendance_break_time#{i + 1}_state_options", :attendance_break_time_options)
      permit_params "attendance_break_time#{i + 1}_state"
      permit_params "attendance_break_enter#{i + 1}_label"
      permit_params "attendance_break_leave#{i + 1}_label"
    end

    field :affair_rounding_time_minute, type: Integer, default: 15

    permit_params :attendance_year_changed_month, :attendance_management_year
    permit_params :attendance_enter_label, :attendance_leave_label
    permit_params :affair_rounding_time_minute

    validates :attendance_year_changed_month, presence: true,
              numericality: { greater_than_or_equal_to: 1, less_than_or_equal_to: 12, allow_blank: true }
    validates :attendance_management_year, presence: true,
              numericality: { greater_than_or_equal_to: 1, less_than_or_equal_to: 99, allow_blank: true }
  end

  def attendance_management_year_options
    (1..10).map do |y|
      [ "#{y}#{I18n.t('datetime.prompts.year')}", y.to_s ]
    end
  end

  def attendance_year_changed_month_options
    (1..12).map do |m|
      [ "#{m}#{I18n.t('datetime.prompts.month')}", m.to_s ]
    end
  end

  def attendance_break_time_options
    %w(hide show).map { |k| [I18n.t("ss.options.state.#{k}"), k] }
  end

  def affair_rounding_time_minute_options
    %w(0 1 5 10 15).map { |k| [I18n.t("gws/affair.options.affair_rounding_time_minute.#{k}"), k] }
  end
end
