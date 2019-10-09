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

  delegate :label, :t, :tt, :attributes, :update, :save, to: :site
  delegate :cur_user, :cur_user=, :updated, to: :site
  delegate :attendance_time_changed_minute, :attendance_time_changed_options, to: :site
  delegate :in_attendance_time_change_hour, :in_attendance_time_change_hour=, to: :site
  delegate :affair_on_duty_working_minute, :affair_on_duty_working_minute=, to: :site
  delegate :affair_on_duty_break_minute, :affair_on_duty_break_minute=, to: :site
  delegate :affair_overtime_working_minute, :affair_overtime_working_minute=, to: :site
  delegate :affair_overtime_break_minute, :affair_overtime_break_minute=, to: :site
  delegate :affair_start_at_hour, :affair_start_at_hour=, :affair_start_at_minute, :affair_start_at_minute=, to: :site
  delegate :affair_end_at_hour, :affair_end_at_hour=, :affair_end_at_minute, :affair_end_at_minute=, to: :site
  delegate :affair_start_at_hour_options, :affair_start_at_minute_options, to: :site
  delegate :affair_end_at_hour_options, :affair_end_at_minute_options, to: :site
end
