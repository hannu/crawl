class Page
  attr_accessor :uid, :title, :url, :content, :bot

  def initialize(properties = {})
    [:uid, :title, :url, :content, :bot].each do |key|
      self.instance_variable_set("@#{key}", properties[key])
    end
  end

  def self.parse_from_string(str)
    title, url, empty_line, content = (commit.tree/filename).data.split("\n",4)
    Page.new({:title => title, :url => url, :content => content})
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