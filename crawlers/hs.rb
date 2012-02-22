
module Crawler
  class HS < Crawler::Bot
    Crawler::BOTS << self
    BOT_DIR = "hs.fi"

    # Loads new entries from RSS feed
    def get_new
      # Parse items from RSS feed
      source = "http://www.hs.fi/uutiset/rss/"
      content = open(source).read
      rss = RSS::Parser.parse(content, false)

      # Get RSS item links
      pages = []
      rss.items.each do |item|
        next unless item.link
        uri = URI.parse(item.link)
        next if !uri or uri.host != "www.hs.fi" # Invalid URL
        uid = uri.path.split("/").last
        pages << Page.new(uid, uri)
      end
      pages
    end

    def parse_title(response)
      c = Nokogiri::HTML(response.body).css('#main-content h1')
      raise ContentParseError if c.length <= 0 or c.first.content.nil?
      c.first.content.strip
    end

    def parse_content(response)
      Nokogiri::HTML(response.body).css('#main-content #article-text p').map{|c|
        raise ContentParseError if c.nil?
        c.content.strip
      }.select{|c| !c.empty?}.join("\n\n")
    end
    
  end
end
