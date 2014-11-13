require 'sinatra/base'
require 'json'
require 'rqrcode'
require 'mini_magick'
require './svg.rb'
require 'erb'

require 'data_mapper'
DataMapper.setup(:default, "sqlite://#{File.expand_path('db/orders.db')}")
require './db/models.rb'

class ApiApp < Sinatra::Base
  configure { set :server, :puma }
  set :api_key, "your_api_key"
  set :event_name, 'YourEventName'
  set :number_of_checkins, 0
  set :number_in_venue, 0
  set :number_of_failed_checkins, 0
  set :orders, []
  set :bind, '0.0.0.0'

  def initialize()
    super()
  end

  # # # # # # # #
  # Visible pages
  before do
    @path_info = request.path_info
    @api_key = settings.api_key
    @event_name = settings.event_name
    @endpoint = request.scheme + '://' + request.host_with_port + "/qr_check_in"
  end

  get '/' do
    erb :layout, :layout => false do
      erb :index
    end
  end

  get '/login' do
    erb :layout, :layout => false do
      erb :login
    end
  end

  get '/orders' do
    orders = []
    Order.all.each do |order|
      customer = order.customer
      composite = {}
      composite[:full_name] = "#{customer[:first_name]} #{customer[:last_name]}"
      has_address = (!customer[:address].nil?)
      composite[:full_address] = "#{customer[:address]}"
      has_postal_info = (!customer[:postal_code].nil? || !customer[:town].nil?)
      composite[:full_address]+= "<br />" if has_address && has_postal_info
      composite[:full_address]+= "#{customer[:postal_code]} " unless customer[:postal_code].nil?
      composite[:full_address]+= "#{customer[:town]}" unless customer[:town].nil?
      composite[:full_address]+= "<br />" if has_postal_info
      composite[:full_address]+= "#{customer[:country]}" unless customer[:country].nil?
      composite[:tickets] = order.tickets.to_a
      orders << composite
    end

    @orders = orders
    @ticket_count = Ticket.count
    erb :layout, :layout => false do
      erb :orders
    end
  end

  get '/get_ticket_info/:ticketToken' do
    @code = params[:ticketToken]
    erb :ticket_info, :layout => false
  end


  # # # # # # # # # # # # # # # # #
  # Requests related to logging in
  get '/get_qr_code_image/:text' do
    content_type 'image/png'
    size   = 6
    level  = :h
    qrcode = RQRCode::QRCode.new(params[:text], :size => size, :level => level)
    svg = RQRCode::Renderers::SVG::render(qrcode, { :unit => 3 })
    image = MiniMagick::Image.read(svg) { |i| i.format "svg" }
    image.format "png"
    image.to_blob
  end

  get '/get_valid_login' do
    content_type 'image/png'
    login_details = {}
    login_details[:e] = "#{request.scheme}://#{request.host}:#{request.port}"
    login_details[:a] = settings.api_key
    size = 8
    level = :h
    qrcode = RQRCode::QRCode.new(login_details.to_json, :size => size, :level => level)
    svg = RQRCode::Renderers::SVG::render(qrcode, { :unit => 3 })
    image = MiniMagick::Image.read(svg) { |i| i.format "svg" }
    image.format "png"
    image.to_blob
  end

  # # # # # # # # # # # # # #
  # QR checkin app requests #

  # Filters
  before '/qr_check_in/*/:apiKey/*' do
    content_type :json
    sleep(0.5)
    if params[:apiKey] != settings.api_key
      halt 401, { :success => false }.to_json
    end
  end

  def event_statistics
    {
      :number_of_checkins => Ticket.count(:checked_in => true),
      :number_in_venue => settings.number_of_checkins, # not used
      :number_of_failed_checkins => settings.number_of_failed_checkins # not used
    }
  end

  get '/qr_check_in/check_endpoint/:apiKey' do
    if params[:apiKey] != settings.api_key
      { :success => false }.to_json
    else
      # current implementation supports only one event
      eventNames = [settings.event_name]
      { :success => true, :allow_manual_checkins => false, :allow_pass_in_out => false, :event_names => eventNames }.to_json
    end
  end

  get '/qr_check_in/get_event_statistics/:apiKey/:eventName' do
    result = {
      :success => true,
      :event_statistics => event_statistics
    }
    result.to_json
  end

  # # # # # # # # # # # # # # # # # # # #
  # Requests related to reading the codes
  get '/qr_check_in/check_in/:apiKey/:eventName/:ticketToken' do
    ticket = Ticket.first(:ticket_code => params[:ticketToken]);
    unless ticket.nil?
      if !ticket[:checked_in]
        order = ticket.order
        customer = order.customer
        full_name = "#{customer[:first_name]} #{customer[:last_name]}"

        ticket[:checked_in] = true
        ticket.save
        result = {
          :ticket_token => params[:ticketToken],
          :success => true,
          :success_message => "Checked In: #{full_name} (#{order.tickets.count(:checked_in => true)}/#{order.tickets.count}).",
          :name => full_name,
          :event_statistics => event_statistics
        }
      else
        result = {
          :success => false,
          :error_message => "Ticket already checked in!",
          :event_statistics => event_statistics
        }
      end
      return result.to_json
    else
      { :success => false }.to_json
    end
  end

  get '/qr_check_in/check_out/:apiKey/:eventName/:ticketToken' do
    ticket = Ticket.first(:ticket_code => params[:ticketToken]);
    unless ticket.nil?
      if ticket[:checked_in]
        ticket[:checked_in] = false
        ticket.save
        result = {
          :ticket_token => params[:ticketToken],
          :success => true,
          :success_message => "Checked out successfully.",
          :event_statistics => event_statistics
        }
      else
        result = {
          :success => false,
          :error_message => "Ticket already checked in!",
          :event_statistics => event_statistics
        }
      end
      return result.to_json
    else
      { :success => false }.to_json
    end
  end

  get '/qr_check_in/perform_manual_checkin/:apiKey/:eventName' do
  end

  get '/qr_check_in/perform_pass_out/:apiKey/:eventName' do
  end

  get '/qr_check_in/perform_pass_in/:apiKey/:eventName' do
  end

  get '/qr_check_in/search/:apiKey/:eventName/:name' do
  end

  # start the server if ruby file executed directly
  run! if app_file == $0
end
