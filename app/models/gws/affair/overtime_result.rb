class Gws::Affair::OvertimeResult
  include SS::Document

  embedded_in :file, class_name: "Gws::Addon::Affair::OvertimeFile"
  field :date, type: DateTime
  field :start_at, type: DateTime
  field :end_at, type: DateTime
  field :break_time_minute, type: Integer, default: 0

  validates :date, presence: true
  validates :start_at, presence: true
  validates :end_at, presence: true
end
