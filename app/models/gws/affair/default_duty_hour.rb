class Gws::Affair::DefaultDutyHour
  include ActiveModel::Model
  include Gws::SitePermission

  set_permission_name "gws_affair_duty_hours"

  def self.wrap(site)
    new(site)
  end

  attr_reader :site
  attr_accessor :cur_site

  def initialize(site)
    @site = site
  end

  def new_record?
    false
  end

  def persisted?
    true
  end

  def destroyed?
    false
  end

  def id
    "default"
  end

  def name
    I18n.t("gws/affair.default_duty_hour")
  end

  def addons
    []
  end

  def lookup_addons
  end

  def method_missing(name, *args, &block)
    if site.respond_to?(name)
      return site.send(name, *args, &block)
    end

    super
  end

  def respond_to_missing?(name, include_private)
    return true if site.respond_to?(name, include_private)

    super
  end
end
