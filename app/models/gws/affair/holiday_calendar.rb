class Gws::Affair::HolidayCalendar
  include SS::Document
  include Gws::Reference::User
  include Gws::Reference::Site
  include Gws::SitePermission

  set_permission_name 'gws_affair_duty_hours'

  field :name, type: String
  has_many :holidays, class_name: 'Gws::Schedule::Holiday', dependent: :destroy, inverse_of: :holiday_calendar

  permit_params :name

  validates :name, presence: true

  class << self
    def search(params)
      criteria = self.where({})
      return criteria if params.blank?

      if params[:name].present?
        criteria = criteria.search_text params[:name]
      end
      if params[:keyword].present?
        criteria = criteria.keyword_in params[:keyword], :name
      end
      criteria
    end
  end
end
