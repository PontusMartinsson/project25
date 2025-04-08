require 'sinatra'
require 'sinatra/reloader'
require 'sinatra/flash'
require 'slim'
require 'sqlite3'
require 'bcrypt'

require_relative 'models'

enable :sessions

get '/' do
  redirect '/project'
end

get '/register' do
  slim :register
end

post '/register' do
  username = params[:username]
  password = params[:password]
  confirmpassword = params[:confirmpassword]

  if db_get('username', 'user').include?(username)
    flash[:message] = 'Username already taken'
    redirect '/register'
  elsif password == confirmpassword
    create_user(username, password)
    redirect '/project'
  else
    flash[:message] = 'Passwords did not match'
    redirect '/register'
  end
end

get '/login' do 
  slim :login
end

post '/login' do
  username = params[:username]
  password = params[:password]

  db = SQLite3::Database.new('db/greja.db')
  db.results_as_hash = true
  result = db.execute("SELECT * FROM user WHERE username = ?", username).first

  if result.nil?
    flash[:message] = 'User does not exist'
    redirect '/login'
  end

  passworddigest = result["password"]

  if BCrypt::Password.new(passworddigest) == password
    session[:id] = result["id"]
    session[:admin] = result["admin"]
    session[:username] = result["username"]
    redirect '/project'
  else
    flash[:message] = 'Password incorrect'
    redirect '/login'
  end
end

get '/logout' do
  session.clear
  redirect '/project'
end

get '/project/admin' do
  if admin?
    @result = db_get('*', 'project', true)
    slim :'project/admin_view'
  else
    redirect '/login'
  end
end

get '/project' do
  name = flash[:name]
  creator = flash[:creator]
  tag = flash[:tag]

  @result = remove_duplicates(projects_search(name, creator, tag))
  # @result = projects_search(name, creator, tag)

  slim :'project/index'
end

post '/project/search' do
  flash[:name] = params['name']
  flash[:creator] = params['creator']
  flash[:tag] = params['tag']
  redirect '/project'
end

get '/project/user/:id' do
  userid = params[:id]
  @result = remove_duplicates(projects_user(userid))
  if session[:id] == userid.to_i || admin?
    slim :'project/index_edit'
  else
    slim :'project/index'
    'grer'
  end
end

get '/project/new' do
  if session[:id].nil?
    redirect '/login'
  end
  @parts = db_get('*', 'part', true)
  slim :'project/create'
end

get '/project/:id' do
  projectid = params[:id]
  @result = project_id(projectid)
  @parts = parts_project(projectid)
  slim :'project/show'
end

post '/project' do
  name = params['name']
  tags = params['tags']

  if db_get('projectname', 'project').include?(name)
    flash[:message] = 'Name already taken'
    redirect '/project/new'
  elsif name.empty?
    flash[:message] = 'Please fill in name'
    redirect '/project/new'
  elsif tags.empty?
    flash[:message] = 'Enter at least one tag'
    redirect '/project/new'
  else
    create_project(params)
    redirect '/project'
  end
end

get '/project/:id/edit' do
  projectid = params[:id]
  if verify_ownership(projectid)
    @result = project_id(projectid)
    @parts = db_get('*', 'part', true)
    @parts_in_use = parts_project(projectid)
    slim :'project/edit'
  else
    redirect '/login'
  end
end

post '/project/:id/delete' do
  projectid = params[:id]
  if verify_ownership(projectid)
    delete_project(projectid)
    redirect '/project'
  else
    redirect '/login'
  end
end

post '/project/:id/update' do
  projectid = params[:id]
  if verify_ownership(projectid)
    delete_project(projectid)
    create_project(params)
    redirect '/project'
  else
    redirect '/login'
  end
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
  if session[:id].nil?
    redirect '/login'
  end
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
    redirect '/part'
  end
end
