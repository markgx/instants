require 'sinatra'
require 'instagram'

CALLBACK_URL = ENV['CALLBACK_URL']

Instagram.configure do |config|
  config.client_id = ENV['CLIENT_ID']
  config.client_secret = ENV['CLIENT_SECRET']
end

enable :sessions

get '/' do
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
  @media_items = client.user_media_feed

  erb :feed
end
