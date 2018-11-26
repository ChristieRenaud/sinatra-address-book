require "sinatra"
require "sinatra/reloader" if development?
require "sinatra/content_for"
require "tilt/erubis"
require "redcarpet"
require "yaml"
require "bcrypt"

configure do
  enable :sessions
  set :session_secret, "very, very, secret"
end

before do
  session[:entries] ||= []
end

helpers do
  def format_phone_number(number)
    number.gsub(/(\d{3})(\d{3})(\d{4})/,'(\1)\2-\3')
  end

  def sort(entries) 
    entries.sort_by { |entry| [entry[:last_name].downcase, entry[:first_name].downcase] }
  end
end

get "/" do
  @entries = session[:entries]


  erb :addresses
end

def next_element_id(elements)
  max = elements.map { |element| element[:id] }.max || 0
  max + 1
end

def load_entry(id)
  session[:entries].find { |entry| entry[:id] == id }
end

get "/:id/edit" do
  @id = params[:id].to_i
  @entry = load_entry(@id)

  erb :edit
end

get "/address/create" do
  erb :add
end

def valid_phone_number(number)
  number.match(/\b\d{10}\b/)
end

def valid_last_name(name)
  name.match(/[a-z]+/i)
end

post "/:id/edit" do
  @id = params[:id].to_i
  @entry = load_entry(@id)
  session[:entries].delete(@entry)
  session[:entries] << { first_name: params["First Name"], last_name: params["Last Name"], id: @id, address: params["Address"], phone_number:  params["Phone Number"]}
  session[:message] = "The entry was edited."
  redirect "/"
end


post "/:id/delete" do
  id = params[:id].to_i
  session[:entries].reject! { |entry| entry[:id] == id}
  session[:message] = "Entry was deleted."
  redirect "/"
end

post "/address/create" do
  params["Phone Number"] = params["Phone Number"].gsub(/[^0-9]/, "")
  if !valid_phone_number(params["Phone Number"])
    session[:message] = "Please enter a 10 digit phone number"
    erb :add
  elsif !valid_last_name(params["Last Name"])
    session[:message] = "Last Name must contain at least 1 letter"
    erb :add
  else
    id = next_element_id(session[:entries])
    session[:entries] << { first_name: params["First Name"], last_name: params["Last Name"], id: id, address: params["Address"], phone_number:  params["Phone Number"]}
    session[:message] = "An entry was added."
    redirect "/"
  end
end

get "/address/search" do

  erb :search
end

# processing search form
get "/address/search/results" do
  @last_name = params[:last_name]
  @results = session[:entries].select { |entry| entry[:last_name].downcase.include?(@last_name.downcase) }

  erb :search
end
