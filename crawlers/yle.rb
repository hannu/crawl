
module Crawler
  class Yle < Crawler::Bot
    Crawler::BOTS << self
    BOT_DIR = "yle.fi"

    # Loads new entries from RSS feed
    def get_new
      # Parse items from RSS feed
      source = "http://yle.fi/uutiset/rss/uutiset.rss"
      content = open(source).read
      rss = RSS::Parser.parse(content, false)

      # Get RSS item links
      pages = []
      rss.items.each do |item|
        next unless item.link
        uri = URI.parse(item.link)
        next if !uri or uri.host != "yle.fi" # Invalid URL  
        uri.query = nil # Remove ..?origin=rss from URL
        uid = /\_([0-9]+)\.html/.match(uri.path)[1]
        pages << Page.new({:uid => uid, :url => uri})
      end
      pages
    end

    # Parse content of the page
    def parse_title(request)
      c = Nokogiri::HTML(request.body).css('#article h1')
      raise ContentParseError if c.length <= 0 or c.first.content.nil?
      c.first.content.strip
    end

    # Parse content of the page
    def parse_content(request)
      Nokogiri::HTML(request.body).css('#article .ingress p', '#article .body p').map{|c|
        raise ContentParseError if c.nil?
        c.content.gsub(/\n/,"").squeeze(" ").strip
      }.select{|c| !c.empty?}.join("\n\n")
    end
  end
end
