module ActiveModel
  class Serializer
    class Adapter
      class JsonApi < Adapter
        module Configuration
          include ActiveSupport::Configurable
          extend ActiveSupport::Concern

          included do |base|
            base.config.default_options = {
              exclude_nil:           false,
              exclude_blank_linkage: false,
              prevent_duplicates:    false
            }
          end
        end
      end
    end
  end
end
