require 'test_helper'

module ActiveModel
  class Serializer
    class LinksTest < Minitest::Test

      def setup
        ActionController::Base.cache_store.clear
        @sitemap = Sitemap.new(id: "1909", title: 'New Post')
        @page = Page.new(id: "1515", title: "foo", href: "https://d2z0k43lzfi12d.cloudfront.net/blog/wp-content/uploads/2015/09/09_02_Teamphoto-e1441186058964.jpg")
        @sitemap.pages = [@page]
      end

      def test_links_in_included
        expected = {
          :data => {
            :id => "1909",
            :type => "sitemaps",
            :relationships => {
              :pages => {
                :data => [
                  {
                    :type => "pages",
                    :id => "1515"
                  }
                ]
              }
            }
          },
          :included => [
            {
              :id => "1515",
              :type => "pages",
              :links => {
                :self => "https://d2z0k43lzfi12d.cloudfront.net/blog/wp-content/uploads/2015/09/09_02_Teamphoto-e1441186058964.jpg"
              }
            }
          ]
        }
        serializer = ::SitemapSerializer.new(@sitemap)
        @adapter = ActiveModel::Serializer::Adapter::JsonApi.new(serializer, include: "pages")

        assert_equal(expected, @adapter.serializable_hash)
      end

      def test_links_in_data
        expected = {
          :data => {
            :id => "1515",
            :type => "pages",
            :links => {
              :self => "https://d2z0k43lzfi12d.cloudfront.net/blog/wp-content/uploads/2015/09/09_02_Teamphoto-e1441186058964.jpg"
            }
          }
        }

        serializer = PageSerializer.new(@page)
        @adapter = ActiveModel::Serializer::Adapter::JsonApi.new(serializer)

        assert_equal(expected, @adapter.serializable_hash)
      end
      
      def test_meta_in_resource
        expected = {
          :data => {
            :id => "1515",
            :type => "pages",
          },
          :meta => {
            :some_info => "i am non compliant info"
          }
        }

        serializer = ::PageMetaSerializer.new(@page)
        @adapter = ActiveModel::Serializer::Adapter::JsonApi.new(serializer)

        assert_equal(expected, @adapter.serializable_hash)
      end
    end
  end
end
