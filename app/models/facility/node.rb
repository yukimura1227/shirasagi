module Facility::Node
  class Base
    include Cms::Node::Model

    default_scope ->{ where(route: /^facility\//) }
  end

  class Node
    include Cms::Node::Model
    include Cms::Addon::NodeList
    include Facility::Addon::CategorySetting
    include Facility::Addon::UseSetting
    include Facility::Addon::LocationSetting

    default_scope ->{ where(route: "facility/node") }
  end

  class Page
    include Cms::Node::Model
    include Facility::Addon::Body
    include Facility::Addon::AdditionalInfo
    include Facility::Addon::Category
    include Facility::Addon::Use
    include Facility::Addon::Location

    default_scope ->{ where(route: "facility/page") }
  end

  class Search
    include Cms::Node::Model
    include Cms::Addon::NodeList
    include Facility::Addon::CategorySetting
    include Facility::Addon::UseSetting
    include Facility::Addon::LocationSetting

    default_scope ->{ where(route: "facility/search") }
  end

  class Category
    include Cms::Node::Model
    include Cms::Addon::NodeList
    include Facility::Addon::PointerImage

    default_scope ->{ where(route: "facility/category") }
  end

  class Use
    include Cms::Node::Model
    include Cms::Addon::NodeList

    default_scope ->{ where(route: "facility/use") }
  end

  class Location
    include Cms::Node::Model
    include Cms::Addon::NodeList

    default_scope ->{ where(route: "facility/location") }
  end
end
