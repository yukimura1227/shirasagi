module Gws::Addon::Affair::Holiday
  extend ActiveSupport::Concern
  extend SS::Addon

  included do
    field :holiday_type, type: String
    has_many :holidays, class_name: 'Gws::Schedule::Holiday', dependent: :destroy, inverse_of: :duty_hour

    permit_params :holiday_type

    validates :holiday_type, presence: true, inclusion: { in: %w(system own), allow_blank: true }
  end

  def holiday_type_options
    %w(system own).map do |v|
      [ I18n.t("gws/affair.options.holiday_type.#{v}"), v ]
    end
  end

  def holiday_type_system?
    !holiday_type_own?
  end

  def holiday_type_own?
    holiday_type == "own"
  end

  def holiday?(user, date)
    if holiday_type_system?
      return Gws::Affair::DefaultDutyHour.holiday?(@cur_site || site, user, date)
    end

    Gws::Schedule::Holiday.site(@cur_site || site).
      and_public.
      and_duty_hour(self).
      allow(:read, user, site: site).
      search(start: date, end: date).present?
  end
end
