# -*- coding: utf-8 -*-
require 'bundler'
require 'open-uri'
require 'digest/sha1'
require 'net/http'
require 'json'

Dir.chdir File.dirname(__FILE__)
Bundler.require
#set :environment, :production

DataMapper::setup(:default, "sqlite3://#{Dir.pwd}/chopstick.db")
class Chopstick
  include DataMapper::Resource
  property :slug, String, :key => true
  property :url, String, :length => 2048, :required => true
  property :content, String, :length => 262144, :required => true
  property :created_at, DateTime, :default => lambda{ |p,s| DateTime.now}
  has n, :comments
end

class Comment
  include DataMapper::Resource
  property :id, Serial
  property :line_no, Integer, :required => true
  property :name, String, :length => 256, :required => true
  property :icon_url, String, :length => 256, :required => true
  property :content, String, :length => 256, :required => true
  property :created_at, DateTime, :default => lambda{ |p,s| DateTime.now}
  belongs_to :chopstick
end
DataMapper.finalize
Chopstick.auto_upgrade!
Comment.auto_upgrade!

get '/application.css' do
  sass :application
end

get '/application.js' do
  coffee :application
end

get '/' do
  @chopsticks = Chopstick.all
  slim :index
end


post '/code/' do
  json = JSON.parse(request.body.string)
  url = json['url']
  content = open(url, :ssl_verify_mode => OpenSSL::SSL::VERIFY_NONE).read
  slug = Digest::SHA1.hexdigest(content)
  p slug
  p url
  chopstick = Chopstick.create({:slug => slug, :url => url, :content => content})
  chopstick.save or raise "Can't save chopstick"
  chopstick.content = nil
  content_type :json
  chopstick.to_json
end

get '/code/:slug' do
  @chopstick = Chopstick.first({:slug => params[:slug]})
  slim :chopstick
end

post '/code/:slug' do
  json = JSON.parse(request.body.string)
  comment = Comment.create(:name => json['name'], :content => json['content'], :icon_url => json['icon_url'], :line_no => json['line_no'])
  chopstick = Chopstick.first({:slug => params[:slug]})
  comment.save
  chopstick.comments << comment
  chopstick.save
  content_type :json
  comment.to_json
end

get '/code/:slug/comments' do
  content_type :json
  Chopstick.first({:slug => params[:slug]}).comments(:order => [:line_no]).to_json
end

not_found do
  'This is nowhere to be found.'
end

error 500 do
  'Sorry there was a nasty error - ' + env['sinatra.error'].name
end
