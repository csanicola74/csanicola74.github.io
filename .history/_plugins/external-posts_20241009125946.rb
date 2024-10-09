require 'feedjira'
require 'httparty'
require 'jekyll'

module ExternalPosts
  class ExternalPostsGenerator < Jekyll::Generator
    safe true
    priority :high

    def generate(site)
      if site.config['external_sources']
        site.config['external_sources'].each do |src|
          p "Fetching external posts from #{src['name']}:"
          xml = HTTParty.get(src['rss_url']).body
          feed = Feedjira.parse(xml)

          feed.entries.each do |e|
            p "...fetching #{e.url}"
            slug = e.title.downcase.strip.gsub(' ', '-').gsub(/[^\w-]/, '')
            path = site.in_source_dir("_posts/#{slug}.md")

            # Create the file if it doesn't exist
            unless File.exist?(path)
              File.open(path, 'w') do |file|
                file.write("---\n")
                file.write("layout: post\n")
                file.write("title: \"#{e.title}\"\n")
                file.write("date: #{e.published}\n")
                file.write("description: \"#{e.summary}\"\n")
                file.write("external_source: #{src['name']}\n")
                file.write("redirect: #{e.url}\n")
                file.write("---\n")
                file.write(e.content) # Add the content after the front matter
              end
            end

            # Load the newly created document into Jekyll
            doc = Jekyll::Document.new(
              path, { site: site, collection: site.collections['posts'] }
            )
            doc.read # Required to read and parse the new file content

            # Add the document to the site's posts collection
            site.collections['posts'].docs << doc
          end
        end
      end
    end
  end
end
