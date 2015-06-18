require 'test_helper'
module ActiveModel
  class Serializer
    class Adapter
      class JsonApi
        class ConfigTest < MiniTest::Test

          def setup
            ActionController::Base.cache_store.clear
            @author = Author.new(id: 1, name: 'Steve K.', nil_attr: nil, posts: [])

            @config = ActiveModel::Serializer::Adapter::JsonApi.config
            @default_options = @config.default_options
          end

          def teardown
            @config.default_options = @default_options
          end

          def adapter
            serializer = ProfileWithNilAttrSerializer.new(@author)
            ActiveModel::Serializer::Adapter::JsonApi.new(serializer)
          end

          def adapter_with_duplicates
            @post = Post.new(id: 123, title: "new_post", body: "some_body", comments: [], blog: nil, author: @author)
            @author.posts = [@post]
            @author.roles = []
            @author.bio   = nil

            serializer = ArraySerializer.new([@author, @post])
            ActiveModel::Serializer::Adapter::JsonApi.new(serializer, include: "posts")
          end

          def test_exclude_nil_false_config
            assert adapter.serializable_hash[:data][:attributes].key?(:nil_attr)
          end

          def test_exclude_nil_true_config
            @config.default_options = { exclude_nil: true }
            refute adapter.serializable_hash[:data][:attributes].key?(:nil_attr)
          end

          def test_exclude_blank_linkage_false_config
            assert adapter.serializable_hash[:data][:relationships].key?(:posts)
          end

          def test_exclude_blank_linkage_true_config
            @config.default_options = { exclude_blank_linkage: true }
            refute adapter.serializable_hash[:data][:relationships].key?(:posts)
          end

          def test_prevent_duplicates_false_config
            h = adapter_with_duplicates.serializable_hash
            assert_equal h[:data].size, 2
            assert_equal h[:included].size, 1
          end

          def test_prevent_duplicates_true_config
            @config.default_options = { prevent_duplicates: true }
            h = adapter_with_duplicates.serializable_hash
            assert_equal h[:data].size, 2
            refute  h.key?(:included) 
          end


        end
      end
    end
  end
end
