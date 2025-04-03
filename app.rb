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

  if password == confirmpassword
    passworddigest = BCrypt::Password.create(password)
    db = SQLite3::Database.new('db/greja.db')
    db.execute("INSERT INTO user (username, password) VALUES (?, ?)", [username, passworddigest])
    redirect '/project'
  else
    "Lösenorden matchade inte"
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
  passworddigest = result["password"]
  id = result["id"]

  if BCrypt::Password.new(passworddigest) == password
    session[:id] = id
    redirect '/project'
  else
    "NEJ"
  end
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

get '/project/new' do
  @parts = parts
  slim :'project/create'
end

get '/project/:projectid' do
  projectid = params[:projectid]
  @result = project_id(projectid)
  slim :'project/show'
end

post '/project' do
  name = params['name']

  if project_names.include?(name)
    flash[:message] = 'Name already taken'
    redirect '/project/new'
  elsif name.empty?
    flash[:message] = 'Please fill in name'
    redirect '/project/new'
  else
    create_project(params)
    redirect '/project'
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
