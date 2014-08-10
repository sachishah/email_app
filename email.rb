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
  subject = strip_html(params[:subject])
  body = strip_html(params[:body])

  mailgun_opts = {
    "from"    => "#{params[:from_name]} <#{params[:from]}>",
    "to"      => "#{params[:to_name]} <#{params[:to]}>",
    "subject" => subject,
    "text"    => body
  }
  mailgun_opts["cc"] = "#{params[:cc_name]} <#{params[:cc]}>" if params[:cc]
  mailgun_opts["bcc"] = "#{params[:bcc_name]} <#{params[:bcc]}>" if params[:bcc]
  response = send_mailgun(mailgun_opts)

  if response.code == "200"
    to_emails = [params[:to], params[:cc], params[:bcc]].compact.join(", ")
    result = "Email successfully sent to #{to_emails}."
    opts = params.merge({
        :subject => subject,
        :body    => body
      })
    result += " Error saving message to db." unless save_record(opts)
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

def save_record(opts)
  receiver = User.first(:email => opts[:to])
  unless receiver # create a new user if he/she doesn't already exist
    receiver = User.new
    receiver.name = opts[:to_name]
    receiver.email = opts[:to]
    receiver.inbox = Inbox.new
    receiver.save!
  end

  message = Message.new
  message.inbox = receiver.inbox
  message.from_email = opts[:from]
  message.received_at = DateTime.now
  message.subject = strip_html(opts[:subject])
  message.body = strip_html(opts[:body])
  message.save!
end
