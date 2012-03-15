require 'rubygems'  if RUBY_VERSION < '1.9'
require 'grit'
require 'json'
require 'sinatra/base'
require File.join(File.dirname(__FILE__), 'page')

# This should be GIT-repository, create it with 'git init'
REPOSITORY_DIR = File.join(File.expand_path(File.dirname(__FILE__)), "repository")

class CrawlerWeb < Sinatra::Base
  set :static, true

  def get_diff(path = nil, date = nil)
    repo = Grit::Repo.new(REPOSITORY_DIR)
    Dir.chdir(REPOSITORY_DIR) do
      diffs = repo.log(nil, path, {:n => 10, :diff_filter => 'M'}).map{ |commit|
        commit.diffs.map { |diff|
          {
            :id => "#{diff.b_path}/#{commit.date.to_i}",
            :path => diff.b_path,
            :date => commit.date,
            :a_blob => Page.parse_from_string(diff.a_blob.data).to_hash,
            :b_blob => Page.parse_from_string(diff.b_blob.data).to_hash
          }
        }
      }.flatten
      diffs = diffs.select{ |diff| diff[:path] == path} if path
      diffs = diffs.select{ |diff| diff[:date].to_i.to_s == date} if date
      diffs = diffs.first if diffs.size == 1
      diffs
    end    
  end

  get '/' do
    File.read(File.join(settings.public_folder, 'index.html'))
  end

  get '/diffs.json' do
    content_type :json
    get_diff.to_json
  end

  get '/diffs/:site/:item.json' do
    content_type :json
    get_diff("#{params[:site]}/#{params[:item]}").to_json
  end

  get '/diffs/:site/:item/:date.json' do
    content_type :json
    get_diff("#{params[:site]}/#{params[:item]}", params[:date]).to_json
  end
end

CrawlerWeb.run!

