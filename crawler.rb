require 'uri'
require 'open-uri'
require 'rss'
require 'rubygems'
require 'nokogiri'
require 'grit'
require 'digest/sha1'

module Crawler
  BOTS = []
  REPOSITORY_DIR = "./repository" # This should be GIT-repository, create it with 'git init'

  def self.repository
    @repo || @repo = Grit::Repo.new(REPOSITORY_DIR)
  end

  def self.increase_item_count
    @items_crawled += 1
  end

  class Page
    attr_accessor :uid, :title, :url, :content, :bot

    def initialize(uid, url)
      @uid = uid
      @url = url
    end

    def exists?
      # Calculate GIT SHA1 hash and check if file already exists in repository
      Crawler.repository.blob(
        Digest::SHA1.hexdigest("blob #{self.to_s.length}\0#{self.to_s}")
      ).size > 0
    end

    def save
      return if self.exists?
      dirname = File.join(Crawler::REPOSITORY_DIR, self.bot.class::BOT_DIR)
      Dir.mkdir(dirname) unless File::exists?(dirname)
      fname = File.join(self.bot.class::BOT_DIR, self.uid)
      File.open(File.join(Crawler::REPOSITORY_DIR, fname), 'w') { |f| f.write(self.to_s) }
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
    unless (self.repository.status.changed + self.repository.status.untracked).empty?
      puts "There are change(s) to be committed"
      Dir.chdir(REPOSITORY_DIR) do
        Crawler.repository.add(".")
      end
      Crawler.repository.commit_index("Update item(s) (#{@items_crawled} items crawled)")
      puts "DONE!"
    else
      puts "No changes found"
    end
  end
end

Crawler.run_all
