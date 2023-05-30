require "sinatra"
require "sinatra/reloader" if development?
require "tilt/erubis"
require "sinatra/content_for"

configure do 
	enable :sessions
	set :session_secret, 'secret'
end 

before do 
  session[:lists] ||= []
end 

helpers do 
  def list_complete?(list)
    todos_count(list) > 0 && todos_remaining_count(list) == 0
  end 

  def list_class(list)
    "complete" if list_complete?(list)
  end 

  def todos_count(list)
    list[:todos].size
  end 

  def todos_remaining_count(list)
    list[:todos].select {|todo| !todo[:completed]}.size
  end 

  def sort_lists(lists)
    complete_lists, incomplete_lists = lists.partition{|list| list_complete?(list)}

    incomplete_lists.each {|list| yield list, lists.index(list)}
    complete_lists.each{|list| yield list, lists.index(list)}
  end 

  def sort_todos(todos)
    complete_todos, incomplete_todos = todos.partition{|todo| todo[:completed]}

    incomplete_todos.each{|todo| yield todo, todos.index(todo)}
    complete_todos.each{|todo| yield todo, todos.index(todo)}
  end 
end 

get "/" do 
  redirect "/lists"
end  

#View all lists
get "/lists" do
  @lists = session[:lists]
  erb :lists,layout: :layout
end

#Render new list form 
get "/lists/new" do 
  erb :new_list, layout: :layout
end 

#Create new list 
post "/lists" do
  list_name = params[:list_name].strip
  error = error_for_list_name(list_name)
  if error
    session[:error] = error
    erb :new_list, layout: :layout
  else
    session[:lists] << {name: list_name, todos: []}
    session[:success] = "The list has been created."
    redirect "/lists"
  end 
end

get "/lists/:list_id" do
  @list = session[:lists][params[:list_id].to_i]
  erb :single_page, layout: :layout
end 

get "/lists/:list_id/edit" do 
  id = params[:list_id].to_i
  @list = session[:lists][id]
  erb :edit_list, layout: :layout 
end 

post "/lists/:list_id" do
  list_name = params[:list_name].strip 
  error = error_for_list_name(list_name)
  id = params[:list_id].to_i
  @list = session[:lists][id]
  if error
    session[:error] = error
    erb :edit_list, layout: :layout
  else
    @list[:name] = list_name 
    session[:success] = "The list has been updated."
    redirect "/lists/#{id}"
  end 
end 

post "/lists/:list_id/delete" do 
  @lists = session[:lists]
  @lists.delete_at(params[:list_id].to_i)
  session[:success] = "The list has been deleted."
  redirect "/lists"
end 

post "/lists/:list_id/todos" do 
  list_id = params[:list_id].to_i 
  @list = session[:lists][list_id]
  todo_name = params[:todo].strip

  error = error_for_todo_name(todo_name)
  if error
    session[:error] = error
    erb :single_page, layout: :layout
  else
    @list[:todos] << {name: todo_name, completed: false}
    session[:success] = "The todo has been added."
    redirect "/lists/#{list_id}"
  end 
end 

post "/lists/:list_id/deletetodo/:todo_id" do
  list_id = params[:list_id].to_i 
  todo_id = params[:todo_id].to_i 
  @lists = session[:lists][list_id][:todos].delete_at(todo_id)
  session[:success] = "The todo has been deleted."
  redirect "/lists/#{list_id}"
end

post "/lists/:list_id/completetodo/:todo_id" do 
  @list_id = params[:list_id].to_i 
  @list = session[:lists][@list_id]

  todo_id = params[:todo_id].to_i 
  is_completed = params[:completed] == 'true'
  @list[:todos][todo_id][:completed] = is_completed
  session[:success] = "The todo is complete."
  redirect "/lists/#{@list_id}"
end 

post "/lists/:list_id/completeall" do 
  @list_id = params[:list_id].to_i 
  @list = session[:lists][@list_id]
  @list[:todos].each{|todo| todo[:completed] = true}
  session[:success] = "All todos have been completed."
  erb :single_page
end 

def error_for_todo_name(text)
  if !(1..100).cover? text.size
    "Todo name must be between 1 and 100 characters"
  end 
end 

def error_for_list_name(name)
  if !(1..100).cover? name.size
    "List name must be between 1 and 100 characters"
  elsif session[:lists].any? {|list| list[:name] == name} 
    "List name must be unique"
  end
end 

# session = {}
# session = {lists: []} 
# session = {lists: [{name:'New Lists', todos:[{name: "", completed: false}]}]}


