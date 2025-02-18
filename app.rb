require 'sinatra'
require 'slim'
require 'sqlite3'
require 'sinatra/reloader'
require 'bcrypt'

require_relative 'models'

enable :sessions

get '/' do
  slim :tja
end

get '/project/browse' do
  @result = projects_public
  slim :'project/browse'
end

get '/project/browse/search/:keyword' do
  keyword = params[:keyword]
  @result = projects_keyword(keyword)
  slim :'project/browse'
end

get '/project/browse/user/:userid' do
  userid = params[:userid]
  @result = projects_user(userid)
  slim :'project/browse'
end

get '/project/show/:projectid' do
  projectid = params[:projectid]
  @result = project_id(projectid)
  slim :'project/show'
end

get '/project/build/:projectid' do

end