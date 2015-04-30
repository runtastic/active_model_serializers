require 'test_helper'

module ActiveModel
  class Serializer
    class Adapter
      class JsonApi
        class LinksTest < Minitest::Test
          class CommentWithLinkSerializer < ActiveModel::Serializer
            def self_link
              "http://fake.com/comments/#{object.id}"
            end
          end

          class CommentWithNilLinkSerializer < ActiveModel::Serializer
            def self_link
              nil
            end
          end

          class PostWithLinksSerializer < ActiveModel::Serializer
            attribute :title
            has_many :comments, serializer: CommentWithLinkSerializer

            def comments_self_link
              "http://fake.com/posts/#{object.id}/comments"
            end

            def comments_related_link
              "http://fake.com/posts/#{object.id}/rel/comments"
            end
          end

          class PostWithNilLinksSerializer < ActiveModel::Serializer
            attribute :title
            has_many :comments, serializer: CommentWithNilLinkSerializer

            def comments_self_link
              nil
            end

            def comments_related_link
              nil
            end
          end


          def setup
            @post = Post.new(id: 1, title: 'Hello!!', body: 'Hello, world!!', comments: [])
            @comment = Comment.new(id: 5)
            ActionController::Base.cache_store.clear
          end

          def test_self_link
            expected = {
              data: {
                id: "5",
                type: "comments",
                links: {
                  self: "http://fake.com/comments/5"
                }
              }
            }
            assert_serialization(CommentWithLinkSerializer, @comment, expected)
          end

          def test_nil_self_link
            expected = {
              data: {
                id: "5",
                type: "comments"
              }
            }
            assert_serialization(CommentWithNilLinkSerializer, @comment, expected)
          end

          def test_association_links
            @post.comments = [@comment]
            expected = {
              data: {
                id: "1",
                type: "posts",
                title: "Hello!!",
                links: {
                  comments: {
                    self: "http://fake.com/posts/1/comments",
                    related: "http://fake.com/posts/1/rel/comments",
                    linkage: [{ id: "5", type: "comments" }]
                  }
                }
              },
              included: [
                {
                   id: "5",
                   type: "comments",
                   links: {
                     self: "http://fake.com/comments/5",
                   }
                }
              ]
            }
            assert_serialization(PostWithLinksSerializer, @post, expected, { include: "comments" })
          end

          def test_nil_association_links
            @post.comments = [@comment]
            expected = {
              data: {
                id: "1",
                type: "posts",
                title: "Hello!!",
                links: {
                  comments: {
                    linkage: [{ id: "5", type: "comments" }]
                  }
                }
              },
              included: [
                {
                   id: "5",
                   type: "comments"
                }
              ]
            }
            assert_serialization(PostWithNilLinksSerializer, @post, expected, { include: "comments" })
          end

          private

          def assert_serialization(serializer_class, object, expected, options = {})
            serializer = serializer_class.new(object)
            adapter = ActiveModel::Serializer::Adapter::JsonApi.new(serializer, options)
            assert_equal(expected, adapter.serializable_hash)
          end
        end
      end
    end
  end
end
