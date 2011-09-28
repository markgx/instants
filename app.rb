require 'sinatra'
require 'instagram'
require 'dalli'

CALLBACK_URL = ENV['CALLBACK_URL']

Instagram.configure do |config|
  config.client_id = ENV['CLIENT_ID']
  config.client_secret = ENV['CLIENT_SECRET']
end

set :cache, Dalli::Client.new

enable :sessions

get '/' do
  @logged_in = !session[:access_token].nil?

  @images = settings.cache.get('popular')
  if @images.nil?
    @images = Instagram.media_popular
    settings.cache.set('popular', @images, 120)
  end

  erb :index
end

get '/login' do
  redirect Instagram.authorize_url(:redirect_uri => CALLBACK_URL)
end

get '/callback' do
  response = Instagram.get_access_token(params[:code], :redirect_uri => CALLBACK_URL)
  session[:access_token] = response.access_token
  redirect '/feed'
end

get '/feed' do
  client = Instagram.client(:access_token => session[:access_token])

  @user = client.user

  cache_key = "#{@user.username}::media_items"
  @media_items = settings.cache.get(cache_key)

  if @media_items.nil?
    @media_items = client.user_media_feed
    settings.cache.set(cache_key, @media_items, 300)
  end

  erb :feed
end
