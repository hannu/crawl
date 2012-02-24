require 'uri'
require 'open-uri'
require 'rss'
require 'rubygems' if RUBY_VERSION < '1.9'
require 'nokogiri'
require 'grit'
require 'digest/sha1'
require File.join(File.dirname(__FILE__), 'page')

module Crawler
  BOTS = []

  # This should be GIT-repository, create it with 'git init'
  REPOSITORY_DIR = File.join(File.expand_path(File.dirname(__FILE__)), "repository")

  def self.repository
    @repo || @repo = Grit::Repo.new(REPOSITORY_DIR)
  end

  def self.increase_item_count
    @items_crawled += 1
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
      page.bot = self
      Crawler.increase_item_count
      response = request_url(page.url)

      if response.is_a?(Net::HTTPSuccess)
        begin
          # Parse content from successful response 
          page.title = parse_title(response)
          page.content = parse_content(response)
        rescue ContentParseError => e
          puts "ERROR: Could not parse content from '#{page.url}'"
          return
        end

      elsif response.is_a?(Net::HTTPMovedPermanently)
        # TODO: Handle redirection loops
        new_uri = URI.parse(response['location'])

        # Redirection does not always contain full url
        # Get host and scheme from url url if needed
        new_uri.host = page.url.host unless new_uri.host
        new_uri.scheme = page.url.scheme unless new_uri.scheme
        page.url = new_uri

        update(page)
        return
      elsif response.is_a?(Net::HTTPNotFound)
        page.title = page.content = ""
      elsif response != false
        puts "#{page.url} returned #{response.class}"
        return
      else
        # We could not resolve the page
        return
      end

      page.save
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
    # Run all bots
    @items_crawled = 0
    BOTS.each { |bot_class| bot_class.new.run }

    # Commit found changes
    puts "#{@items_crawled} item(s) crawled"
    Dir.chdir(REPOSITORY_DIR) do
      # Commit new files
      if (new_count = self.repository.status.untracked.length) > 0
        self.repository.status.untracked.each {|filename, statusfile| Crawler.repository.add(filename)}
        Crawler.repository.commit_index("Add #{new_count} item(s)")
      end

      # Commit changed files
      if (changed_count = self.repository.status.changed.length) > 0
        self.repository.status.changed.each {|filename, statusfile| Crawler.repository.add(filename)}
        Crawler.repository.commit_index("Updated #{changed_count} item(s)")
      end
      puts "Added #{new_count} new item(s) and updated #{changed_count} item(s)"
    end
  end
end

Crawler.run_all
