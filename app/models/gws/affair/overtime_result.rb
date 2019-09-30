class Gws::Affair::OvertimeResult
  include SS::Document

  field :start_at, type: DateTime
  field :end_at, type: DateTime
  belongs_to :capital, class_name: "Gws::Affair::Capital"

  embedded_in :file, inverse_of: :results

  validates :start_at, presence: true
  validates :end_at, presence: true
  validates :capital_id, presence: true
end
