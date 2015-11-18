require 'test_helper'

module ActiveModel
  class Serializer
    class JsonApiTest < Minitest::Test
      def setup
        ActionController::Base.cache_store.clear
        @blog = Blog.new(id: 1,
                         name: 'AMS Hints',
                         writer: Author.new(id: 2, name: "Steve"),
                         articles: [Post.new(id: 3, title: "AMS")])
      end

      def test_jsonapi
        serializer = AlternateBlogSerializer.new(@blog)
        adapter = ActiveModel::Serializer::Adapter::JsonApi.new(serializer, root: 'blog', jsonapi: { version: "1.0" })
        expected = {
          data: {
            id: "1",
            type: "blogs",
            attributes: {
              title: "AMS Hints"
            }
          },
          jsonapi: {
            version: "1.0"
          }
        }
        assert_equal expected, adapter.as_json
      end

    end
  end
end
