module ActiveModel
  class Serializer
    class Adapter
      class JsonApi < Adapter
        def initialize(serializer, options = {})
          super
          serializer.root = true
          @hash = { data: [] }

          if fields = options.delete(:fields)
            @fieldset = ActiveModel::Serializer::Fieldset.new(fields, serializer.json_key)
          else
            @fieldset = options[:fieldset]
          end
        end

        def serializable_hash(options = {})
          hash = serializable_hash_with_duplicates
          remove_duplicates(hash)
        end

        protected

        def serializable_hash_with_duplicates
          if serializer.respond_to?(:each)
            serializer.each do |s|
              result = self.class.new(s, @options.merge(fieldset: @fieldset)).serializable_hash_with_duplicates
              @hash[:data] << result[:data]

              if result[:included]
                @hash[:included] ||= []
                @hash[:included] |= result[:included]
              end
            end
          else
            @hash = cached_object do
              @hash[:data] = attributes_for_serializer(serializer, @options)
              add_resource_links(@hash[:data], serializer)
              @hash
            end
          end
          @hash
        end

        private

        def remove_duplicates(hash)
          if @options[:prevent_duplicates] && hash[:included] && hash[:data].is_a?(Array)
            ids_per_type = {}
            hash[:data].each do |resource|
              type = resource[:type]
              ids_per_type[type] ||= Set.new
              ids_per_type[type] << resource[:id]
            end
            hash[:included].select! do |included|
              type = included[:type]
              id   = included[:id]
              not_in_data?(ids_per_type, type, id)
            end
            hash.delete(:included) if hash[:included].empty?
          end
          hash
        end

        def not_in_data?(ids_per_type, type, id)
          !ids_per_type[type].try(:include?, id)
        end

        def add_link_urls(link, assoc_name, serializer)
          [:self, :related].each do |url_key|
            url_method = "#{assoc_name}_#{url_key}_link"
            next unless serializer.respond_to?(url_method)
            url = serializer.send(url_method)
            link[url_key] = url if url
          end
        end

        def add_links(resource, name, assoc_serializers, serializer)
          resource[:links] ||= {}
          resource[:links][name] ||= { linkage: [] }
          link = resource[:links][name]
          add_link_urls(link, name, serializer)
          link[:linkage] += assoc_serializers.map { |serializer| { type: serializer.type, id: serializer.id.to_s } }
        end

        def add_link(resource, name, assoc_serializer, serializer)
          resource[:links] ||= {}
          resource[:links][name] = { linkage: nil }
          link = resource[:links][name]
          add_link_urls(link, name, serializer)
          if assoc_serializer && assoc_serializer.object
            link[:linkage] = { type: assoc_serializer.type, id: assoc_serializer.id.to_s }
          end
        end

        def add_included(resource_name, serializers, parent = nil)
          unless serializers.respond_to?(:each)
            return unless serializers.object
            serializers = Array(serializers)
          end
          resource_path = [parent, resource_name].compact.join('.')
          if include_assoc?(resource_path)
            @hash[:included] ||= []

            serializers.each do |serializer|
              attrs = attributes_for_serializer(serializer, @options)

              add_resource_links(attrs, serializer, add_included: false)

              @hash[:included].push(attrs) unless @hash[:included].include?(attrs)
            end
          end

          serializers.each do |serializer|
            serializer.each_association do |name, association, opts|
              add_included(name, association, resource_path) if association
            end if include_nested_assoc? resource_path
          end
        end

        def attributes_for_serializer(serializer, options)
          if serializer.respond_to?(:each)
            result = []
            serializer.each do |object|
              options[:fields] = @fieldset && @fieldset.fields_for(serializer)
              options[:required_fields] = [:id, :type]
              attributes = object.attributes(options)
              attributes[:id] = attributes[:id].to_s
              result << attributes
            end
          else
            options[:fields] = @fieldset && @fieldset.fields_for(serializer)
            options[:required_fields] = [:id, :type]
            result = serializer.attributes(options)
            result[:id] = result[:id].to_s
          end

          result
        end

        def include_assoc?(assoc)
          return false unless @options[:include]
          check_assoc("#{assoc}$")
        end

        def include_nested_assoc?(assoc)
          return false unless @options[:include]
          check_assoc("#{assoc}.")
        end

        def check_assoc(assoc)
          include_opt = @options[:include]
          include_opt = include_opt.split(',') if include_opt.is_a?(String)
          include_opt.any? do |s|
            s.match(/^#{assoc.gsub('.', '\.')}/)
          end
        end

        def add_resource_links(attrs, serializer, options = {})
          options[:add_included] = options.fetch(:add_included, true)
          attrs[:links] ||= {}
          self_link = serializer.self_link if serializer.respond_to?(:self_link)
          attrs[:links][:self] = self_link if self_link

          serializer.each_association do |name, association, opts|
            if association.respond_to?(:each)
              add_links(attrs, name, association, serializer)
            else
              add_link(attrs, name, association, serializer)
            end

            if options[:add_included]
              Array(association).each do |association|
                add_included(name, association)
              end
            end
          end
          attrs.delete(:links) if attrs[:links].empty?
        end
      end
    end
  end
end
