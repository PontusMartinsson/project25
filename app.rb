require 'sinatra'
require 'sinatra/reloader'
require 'sinatra/flash'
require 'slim'
require 'sqlite3'
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

get '/project/create' do
  @parts = parts
  slim :'project/create'
end

post '/project/new' do
  parts = params.select { |item| item.start_with?('part') }.values
  parts.map! { |item| item.to_i }
  p parts
  redirect '/project/create'
end

# /project/edit

# get '/part/browse' do
#   @result = parts
#   slim :'part/browse'
# end

get '/part/browse' do # TRASIGT
  @result = parts_search(flash[:name], flash[:type])
  p @result
  slim :'part/browse'
end

post '/part/search' do # TRASIGT
  flash[:name] = params[:name]
  flash[:type] = params[:type]
  redirect '/part/browse'
end

get '/part/create' do
  slim :'part/create'
end

post '/part/new' do
  name = params[:name]
  type = params[:type]

  if verify_part_creation(name, type)
    flash[:message] = 'That part already exists'
    redirect '/part/create'
  elsif name.empty? || type.empty?
    flash[:message] = 'All fields must be filled in'
    redirect '/part/create'
  else
    create_part(name, type)
    redirect '/'
  end
end
