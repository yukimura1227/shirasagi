class Gws::Affair::OvertimeFile
  include SS::Document
  include Gws::Referenceable
  include Gws::Reference::User
  include Gws::Reference::Site
  include Gws::Addon::Affair::OvertimeResult
  include Gws::Addon::Affair::OvertimeDayResult
  include Gws::Addon::Affair::Approver
  include Gws::Addon::Affair::OvertimeFile
  include Gws::Addon::GroupPermission
  include Gws::Addon::History
  include Gws::Affair::Searchable

  # rubocop:disable Style/ClassVars
  @@approver_user_class = Gws::User
  # rubocop:enable Style/ClassVars

  seqid :id
  field :state, type: String, default: 'closed'
  field :name, type: String

  belongs_to :capital, class_name: "Gws::Affair::Capital"

  permit_params :state, :name, :capital_id

  validates :state, presence: true
  validates :name, presence: true, length: { maximum: 80 }
  validates :capital_id, presence: true

  # indexing to elasticsearch via companion object
  #around_save ::Gws::Elasticsearch::Indexer::OvertimeFileJob.callback
  #around_destroy ::Gws::Elasticsearch::Indexer::OvertimeFileJob.callback

  default_scope -> {
    order_by updated: -1
  }

  def private_show_path
    url_helper = Rails.application.routes.url_helpers
    url_helper.gws_affair_overtime_file_path(id: id, site: site, state: 'all')
  end

  def workflow_wizard_path
    url_helper = Rails.application.routes.url_helpers
    url_helper.gws_affair_overtime_wizard_path(site: site.id, id: id)
  end

  def workflow_pages_path
    url_helper = Rails.application.routes.url_helpers
    url_helper.gws_affair_overtime_file_path(site: site.id, id: id, state: "all")
  end
end
