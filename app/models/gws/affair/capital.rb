class Gws::Affair::Capital
  include SS::Document
  include Gws::Referenceable
  include Gws::Reference::User
  include Gws::Reference::Site
  include Gws::Addon::ReadableSetting
  include Gws::Addon::GroupPermission
  include Gws::Addon::History

  seqid :id
  field :name, type: String
  field :order, type: Integer, default: 0
  field :remark, type: String

  permit_params :name
  permit_params :order
  permit_params :remark

  validates :name, presence: true

  scope :site, ->(site) { self.in(group_ids: Gws::Group.site(site).pluck(:id)) }

  def order
    value = self[:order].to_i
    value < 0 ? 0 : value
  end

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
