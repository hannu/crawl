require 'rubygems'  if RUBY_VERSION < '1.9'
require 'grit'
require 'json'
require 'sinatra/base'
require File.join(File.dirname(__FILE__), 'page')

# This should be GIT-repository, create it with 'git init'
REPOSITORY_DIR = File.join(File.expand_path(File.dirname(__FILE__)), "repository")

class CrawlerWeb < Sinatra::Base
  set :static, true

  get '/' do
    File.read(File.join(settings.public_folder, 'index.html'))
  end

  get '/diffs.json' do
    content_type :json
    repo = Grit::Repo.new(REPOSITORY_DIR)
    Dir.chdir(REPOSITORY_DIR) do
      repo.log(nil,nil,{:n => 10, :diff_filter => 'M'}).map{ |c|
        c.diffs.map { |diff|
          {
            :id => "#{diff.b_path}/#{c.date.to_i}",
            :path => diff.b_path,
            :date => c.date,
            :a_blob => Page.parse_from_string(diff.a_blob.data).to_hash,
            :b_blob => Page.parse_from_string(diff.b_blob.data).to_hash
          }
        }
      }.flatten.to_json
    end
  end

  get '/diffs/:path/:id.json' do
    content_type :json
    filename = File.join(params[:path],params[:id])
    repo = Grit::Repo.new(REPOSITORY_DIR)
    Dir.chdir(REPOSITORY_DIR) do
      repo.log(filename).map{ |commit|
        Page.parse_from_string((commit.tree/filename).data).to_hash.merge({:date => commit.date, :path => filename})
      }.to_json
    end
  end
end

CrawlerWeb.run!

