require 'uri'
require 'open-uri'
require 'rss'
require 'rubygems'
require 'nokogiri'

module Crawler
  BOTS = []

  class Page
    attr_accessor :uid, :title, :url, :content

    def initialize(uid, url)
      @uid = uid
      @url = url
    end
    
    def to_s
      "#{title}\n#{url}\n\n#{content}"
    end
  end

  class Bot
    # Fake chrome user agent
    USER_AGENT = "Mozilla/5.0 (X11; Linux i686) AppleWebKit/535.1 (KHTML, like Gecko) Chrome/13.0.782.107 Safari/535.1"

    class ContentParseError < StandardError
    end

    # Loads new entries from RSS feed or other source
    def get_new
      #NOTE: This is implemented in subclass
    end

    # Parse content of the page
    def parse_content
      #NOTE: This is implemented in subclass
    end

    def update(page)
      response = request_url(page.url)

      puts page.uid
      puts page.url

      if response.is_a?(Net::HTTPSuccess)
        begin
          # Parse content from successful response 
          page.title = parse_title(response)
          page.content = parse_content(response)
        rescue ContentParseError => e
          puts "ERROR: Could not parse content from '#{page.url}'"
        end

      elsif response.is_a?(Net::HTTPMovedPermanently)
        # TODO: Handle redirection loops
        new_uri = URI.parse(response['location'])

        # Redirection does not always contain full url
        # Get host and scheme from url url if needed
        new_uri.host = uri.host unless new_uri.host
        new_uri.scheme = uri.scheme unless new_uri.scheme
        page.url = new_uri
        
        update(page)
        return
      elsif response.is_a?(Net::HTTPNotFound)
      elsif response != false
        puts "#{page.url} returned #{response.class}"
        return
      else
        # We could not resolve the page
        return
      end
      
      puts page.title
      puts page.content
      puts "-"*80
    end

    def run
      get_new.each do |page|
        update(page)
      end
    end

    private

    def request_url(uri)
      http = Net::HTTP.new(uri.host, uri.port)
      request = Net::HTTP::Get.new(uri.request_uri)
      request.initialize_http_header({"User-Agent" => USER_AGENT})
      http.request(request)
    rescue StandardError, Timeout::Error => e
      # TODO: Log error
      false
    end
  end

  # Load all crawlers
  Dir[File.join(File.dirname(__FILE__),"crawlers/*.rb")].uniq.each do |file|
    require file
  end

  def self.run_all
    BOTS.each do |bot_class|
      bot = bot_class.new
      bot.run
    end
  end
end

Crawler.run_all
