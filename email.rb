require 'sinatra'
require 'data_mapper'
require 'dm-core'
require 'dm-migrations'
require 'net/http'
require 'uri'

$config = YAML.load_file(File.join(Dir.pwd, 'config.yml'))

DataMapper.setup( :default, "sqlite3://#{Dir.pwd}/rolodex.db" )

class User
  include DataMapper::Resource

  has 1, :inbox

  property :id, Serial
  property :name, String, required: true, length: 3..255
  property :email, String, format: :email_address, required: true
end

class Inbox
  include DataMapper::Resource

  belongs_to :user, key: true, uniquess: true
  has n, :messages
end

class Message
  include DataMapper::Resource

  belongs_to :inbox

  property :id, Serial
  property :from_email, String, format: :email_address, required: true
  property :received_at, DateTime, required: true
  property :subject, String, required: true
  property :body, Text, required: true
end

configure :test do
  DataMapper.finalize
  DataMapper.auto_upgrade!
end


get '/email' do
  erb :index
end

post '/email' do
  from = "#{params[:from_name]} <#{params[:from]}>"
  to = "#{params[:to_name]} <#{params[:to]}>"
  subject = strip_html(params[:subject])
  body = strip_html(params[:body])

  response = send_mailgun({
      "from"    => from,
      "to"      => to,
      "subject" => subject,
      "text"    => body
    })

  if response.code == "200"
    result = "Email successfully sent to #{from}."

    # save record to database
    receiver = User.first(:email => params[:to])
    unless receiver
      receiver = User.new
      receiver.name = params[:to_name]
      receiver.email = params[:to]
      receiver.inbox = Inbox.new
      receiver.save!
    end

    message = Message.new
    message.inbox = receiver.inbox
    message.from_email = params[:from]
    message.received_at = DateTime.now
    message.subject = subject
    message.body = body

    result += " Error saving message to db." unless message.save!
  else
    result = "Error sending email via Mailgun."
  end

  erb :show, :locals => { 'message' => result }
end


private

def strip_html(html_text)
  Nokogiri::HTML(html_text).text
end

def send_mailgun(opts)
  uri = URI.parse($config['mailgun_api_url'])
  Net::HTTP.post_form(uri, opts)
end
