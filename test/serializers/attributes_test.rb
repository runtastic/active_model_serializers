require 'test_helper'

module ActiveModel
  class Serializer
    class AttributesTest < Minitest::Test
      def setup
        @profile = Profile.new({ name: 'Name 1', description: 'Description 1', comments: 'Comments 1', nothing: nil })
        @profile_serializer = ProfileWithNilAttrSerializer.new(@profile)
        @comment = Comment.new(id: 1, body: "ZOMG!!", date: "2015")
        @serializer_klass = Class.new(CommentSerializer)
        @serializer_klass_with_new_attributes = Class.new(CommentSerializer) do
          attributes :date, :likes
        end
      end

      def test_attributes_definition
        assert_equal([:name, :description, :nil_attr],
                     @profile_serializer.class._attributes)
      end

      def test_attributes_with_fields_option
        assert_equal({name: 'Name 1'},
                     @profile_serializer.attributes(fields: [:name]))
      end

      def test_required_fields
        assert_equal({name: 'Name 1', description: 'Description 1'},
                     @profile_serializer.attributes(fields: [:name, :description], required_fields: [:name]))

      end

      def test_exclude_nil_true
        assert_equal({name: 'Name 1', description: 'Description 1'},
                     @profile_serializer.attributes(exclude_nil: true))

      end

      def test_exclude_nil_false
        assert_equal({name: 'Name 1', description: 'Description 1', nil_attr: nil },
                     @profile_serializer.attributes(exclude_nil: false))
      end

      def test_attributes_inheritance_definition
        assert_equal([:id, :body], @serializer_klass._attributes)
      end

      def test_attributes_inheritance
        serializer = @serializer_klass.new(@comment)
        assert_equal({id: 1, body: "ZOMG!!"},
                     serializer.attributes)
      end

      def test_attribute_inheritance_with_new_attribute_definition
        assert_equal([:id, :body, :date, :likes], @serializer_klass_with_new_attributes._attributes)
        assert_equal([:id, :body], CommentSerializer._attributes)
      end

      def test_attribute_inheritance_with_new_attribute
        serializer = @serializer_klass_with_new_attributes.new(@comment)
        assert_equal({id: 1, body: "ZOMG!!", date: "2015", likes: nil},
                     serializer.attributes)
      end

      def test_multiple_calls_with_the_same_attribute
        serializer_class = Class.new(ActiveModel::Serializer) do
          attributes :id, :title
          attributes :id, :title, :title, :body
        end

        assert_equal([:id, :title, :body], serializer_class._attributes)
      end
    end
  end
end
