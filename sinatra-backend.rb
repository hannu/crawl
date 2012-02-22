require 'rubygems'  if RUBY_VERSION < '1.9'
require 'nokogiri'
require 'grit'
require 'json'
require 'sinatra/base'

REPOSITORY_DIR = "./repository" # This should be GIT-repository, create it with 'git init'

class CrawlerWeb < Sinatra::Base
  set :static, true
  
  get '/' do
    File.read(File.join(settings.public_folder, 'index.html'))
  end
  
  get '/globs.json' do
  end
  
  get '/globs/:path/:id.json' do
    content_type :json
    
    filename = File.join(params[:path],params[:id])
    repo = Grit::Repo.new(REPOSITORY_DIR)
    globs = []
    Dir.chdir(REPOSITORY_DIR) do
      globs = repo.log(filename).collect do |commit|
        title, url, empty_line, content = (commit.tree/filename).data.split("\n",4)
        {:title => title, :url => url, :content => content, :date => commit.date}
      end
    end
    globs.to_json
  end
end

CrawlerWeb.run!

