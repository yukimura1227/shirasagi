# "Post" class for BBS. It represents "comment" models.
class Gws::Monitor::Post
  include Gws::Referenceable
  include Gws::Monitor::Postable
  include Gws::Addon::Monitor::Contributor
  include SS::Addon::Markdown
  include Gws::Addon::File
  include Gws::Monitor::DescendantsFileInfo
  include Gws::Addon::GroupPermission
  include Gws::Addon::History
  include Gws::Addon::Monitor::Category
  include Gws::Addon::ReadableSetting

  readable_setting_include_custom_groups

  # indexing to elasticsearch via companion object
  around_save ::Gws::Elasticsearch::Indexer::MonitorPostJob.callback
  around_destroy ::Gws::Elasticsearch::Indexer::MonitorPostJob.callback
end
