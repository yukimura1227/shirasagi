module Gws::Addon::Affair::OvertimeFile
  extend ActiveSupport::Concern
  extend SS::Addon

  included do
    field :overtime_name, type: String
    field :start_at, type: DateTime
    field :end_at, type: DateTime
    field :remark, type: String

    permit_params :overtime_name
    permit_params :start_at
    permit_params :end_at
    permit_params :remark

    validates :overtime_name, presence: true
    validates :start_at, presence: true, datetime: true
    validates :end_at, presence: true, datetime: true

    validate :validate_start_at
  end

  def validate_start_at
    return if start_at.blank?
    return if end_at.blank?

    if start_at >= end_at
      errors.add :end_at, :greater_than, count: t(:start_at)
    end

    if end_at >= start_at.advance(days: 1)
      errors.add :end_at, "が残業開始日時より１日以上経過しています。１日以内で設定してください。"
    end

    return if errors.present?

    duty_hour = cur_user.effective_duty_hour(cur_site || self.site)
    affair_start = duty_hour.affair_start(start_at)
    affair_end = duty_hour.affair_end(start_at)
    if end_at > affair_start && start_at < affair_end
      errors.add :base, "残業開始〜残業終了時間が勤務時間内です。勤務時間外で設定してください。"
      return
    end

    affair_start = duty_hour.affair_start(end_at)
    affair_end = duty_hour.affair_end(end_at)
    if end_at > affair_start && start_at < affair_end
      errors.add :base, "残業開始〜残業終了時間が勤務時間内です。勤務時間外で設定してください。"
    end
  end
end
