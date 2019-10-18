class Gws::Affair::LeaveFile
  include SS::Document
  include Gws::Referenceable
  include Gws::Reference::User
  include Gws::Reference::Site
  include Gws::Addon::Affair::Approver
  include Gws::Addon::Affair::LeaveFile
  include Gws::Addon::ReadableSetting
  include Gws::Addon::GroupPermission
  include Gws::Addon::History
  include Gws::Affair::Searchable

  cattr_reader(:approver_user_class) { Gws::User }

  seqid :id
  field :state, type: String, default: 'closed'
  field :name, type: String

  permit_params :state, :name

  validates :state, presence: true
  validates :name, presence: true, length: { maximum: 80 }

  # indexing to elasticsearch via companion object
  #around_save ::Gws::Elasticsearch::Indexer::LeaveFileJob.callback
  #around_destroy ::Gws::Elasticsearch::Indexer::LeaveFileJob.callback

  default_scope -> {
    order_by updated: -1
  }

  def private_show_path
    url_helper = Rails.application.routes.url_helpers
    url_helper.gws_affair_leave_file_path(id: id, site: site, state: 'all')
  end
end
