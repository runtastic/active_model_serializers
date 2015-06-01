module ActiveModel
  class Serializer
    class Adapter
      class JsonApi < Adapter
        module Configuration
          include ActiveSupport::Configurable
          extend ActiveSupport::Concern

          included do |base|
            base.config.default_options = { include_blank_linkage: true }
          end
        end
      end
    end
  end
end
