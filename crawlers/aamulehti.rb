module Crawler
  class Aamulehti < Crawler::Bot
    Crawler::BOTS << self
    BOT_DIR = "aamulehti.fi"

    # Loads new entries from RSS feed
    def get_new
      # Parse items from RSS feed
      source = "http://www.aamulehti.fi/cs/Satellite?c=AMChannelFeed_C&cid=1194627332523&p=1194596117294&pagename=KAL_newssite%2FAMChannelFeed_C%2FAMArticleFeedIngressRSS20"
      content = open(source).read
      rss = RSS::Parser.parse(content, false)

      # Get RSS item links
      pages = []
      rss.items.each do |item|
        next unless item.link
        uri = URI.parse(item.link)
        next if !uri or uri.host != "www.aamulehti.fi" # Invalid URL
        uid = /\/([0-9]+)/.match(uri.path)[1]
        pages << Page.new(uid, uri)
      end
      pages
    end

    # Parse content of the page
    def parse_title(request)
      c = Nokogiri::HTML(request.body).css('#article h1').first
      raise ContentParseError if c.content.nil?
      c.content.strip
    end
    
    def parse_content(request)
      Nokogiri::HTML(request.body).css('#article p').map{|c|
        raise ContentParseError if c.content.nil?
        c.content.strip
      }.select{|c| !c.empty?}.join("\n\n")
    end
  end
end
