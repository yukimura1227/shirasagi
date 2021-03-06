class SS::ThumbFile
  include SS::Model::File

  default_scope ->{ where(model: "ss/thumb_file") }

  index({ original_id: 1 })

  field :original_id, type: Integer
  field :image_size, type: SS::Extensions::Sizes
  field :image_size_name, type: String

  validates :original_id, presence: true
  validates :image_size, presence: true
  validates :image_size_name, presence: true

  def public_path
    return if site.blank? || !site.respond_to?(:root_path)
    "#{site.root_path}/fs/" + original_id.to_s.split(//).join("/") + "/_/thumb/#{filename}"
  end

  def url
    "/fs/" + original_id.to_s.split(//).join("/") + "/_/thumb/#{filename}"
  end

  def remove_file
    Fs.rm_rf(path)
    remove_public_file
  end
end
