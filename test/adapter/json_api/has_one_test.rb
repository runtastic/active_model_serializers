require 'test_helper'

module ActiveModel
  class Serializer
    class Adapter
      class JsonApi
        class HasOneTest < Minitest::Test
          def setup
            @author = Author.new(id: 1, name: 'Steve K.')
            @bio = Bio.new(id: 43, content: 'AMS Contributor')
            @author.bio = @bio
            @bio.author = @author
            @post = Post.new(id: 42, title: 'New Post', body: 'Body')
            @anonymous_post = Post.new(id: 43, title: 'Hello!!', body: 'Hello, world!!')
            @comment = Comment.new(id: 1, body: 'ZOMG A COMMENT')
            @post.comments = [@comment]
            @anonymous_post.comments = []
            @comment.post = @post
            @comment.author = nil
            @post.author = @author
            @anonymous_post.author = nil
            @blog = Blog.new(id: 1, name: "My Blog!!")
            @blog.writer = @author
            @blog.articles = [@post, @anonymous_post]
            @author.posts = []
            @author.roles = []

            @serializer = AuthorSerializer.new(@author)
            @adapter = ActiveModel::Serializer::Adapter::JsonApi.new(@serializer, include: 'bio,posts')
            ActionController::Base.cache_store.clear
          end

          def test_includes_bio_id
            expected = { data: { type: "bios", id: "43" } }
            assert_equal(expected, @adapter.serializable_hash[:data][:relationships][:bio])
          end

          def test_includes_nil_bio_linkage
            @author.bio = nil
            expected = { data: nil }

            assert_equal(expected, @adapter.serializable_hash[:data][:relationships][:bio])
          end

          def test_exclude_blank_linkage_option_set_to_true
            @author.bio = nil
            @adapter = ActiveModel::Serializer::Adapter::JsonApi.new(@serializer, exclude_blank_linkage: true)

            refute @adapter.serializable_hash[:data][:relationships].key?(:bio)
          end

          def test_exclude_blank_linkage_config
            config = ActiveModel::Serializer::Adapter::JsonApi.config
            default_options = config.default_options
            config.default_options = { exclude_blank_linkage: true }

            @author.bio = nil
            @adapter = ActiveModel::Serializer::Adapter::JsonApi.new(@serializer, include: 'bio,posts')

            refute @adapter.serializable_hash[:data][:relationships].key?(:bio)

            config.default_options = default_options
          end

          def test_includes_linked_bio
            @adapter = ActiveModel::Serializer::Adapter::JsonApi.new(@serializer, include: 'bio')

            expected = [
              {
                id: "43",
                type: "bios",
                attributes: {
                  content:"AMS Contributor",
                  rating: nil
                },
                relationships: {
                  author: { data: { type: "authors", id: "1" } }
                }
              }
            ]

            assert_equal(expected, @adapter.serializable_hash[:included])
          end
        end
      end
    end
  end
end
