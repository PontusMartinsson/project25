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

get '/project' do
  # @result = projects_public
  @result = projects_search(flash[:name], flash[:creator], flash[:tag])
  slim :'project/index'
end

post '/project/search' do
  flash[:name] = params['name']
  flash[:creator] = params['creator']
  flash[:tag] = params['tag']
  redirect '/project'
end

get '/project/user/:userid' do
  userid = params[:userid]
  @result = projects_user(userid)
  slim :'project/index'
end

get '/project/:projectid' do
  projectid = params[:projectid]
  @result = project_id(projectid)
  slim :'project/show'
end

get '/project/new' do
  @parts = parts
  slim :'project/create'
end

post '/project' do
  parts = params.select { |item| item.start_with?('part') }.values
  parts.map! { |item| item.to_i }
  p parts
  redirect '/project/new'
end

get '/part' do
  @result = parts_search(flash[:name], flash[:type])
  slim :'part/index'
end

post '/part/search' do
  flash[:name] = params['name']
  flash[:type] = params['type']
  redirect '/part'
end

get '/part/new' do
  slim :'part/create'
end

post '/part' do
  name = params[:name]
  type = params[:type]

  if verify_part_creation(name, type)
    flash[:message] = 'That part already exists'
    redirect '/part/new'
  elsif name.empty? || type.empty?
    flash[:message] = 'All fields must be filled in'
    redirect '/part/new'
  else
    create_part(name, type)
    redirect '/'
  end
end
