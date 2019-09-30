class Gws::Affair::Dutyhour
  include SS::Document
  include Gws::Referenceable
  include Gws::Reference::User
  include Gws::Reference::Site
  include Gws::Addon::ReadableSetting
  include Gws::Addon::GroupPermission
  include Gws::Addon::History

  seqid :id
  field :name, type: String
  field :start_at, type: Time
  field :end_at, type: Time
  field :break_enter1_start_at, type: Time
  field :break_enter1_end_at, type: Time
  field :break_enter2_start_at, type: Time
  field :break_enter2_end_at, type: Time
  field :break_enter3_start_at, type: Time
  field :break_enter3_end_at, type: Time

  permit_params :name
  permit_params :start_at
  permit_params :end_at
  permit_params :break_enter1_start_at
  permit_params :break_enter1_end_at
  permit_params :break_enter2_start_at
  permit_params :break_enter2_end_at
  permit_params :break_enter3_start_at
  permit_params :break_enter3_end_at

  validates :name, presence: true
  validates :start_at, presence: true
  validates :end_at, presence: true

  scope :site, ->(site) { self.in(group_ids: Gws::Group.site(site).pluck(:id)) }

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
