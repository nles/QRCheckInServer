require 'data_mapper'
DataMapper.setup(:default, "sqlite://#{File.expand_path('db/orders.db')}")
require './db/models.rb'

require 'csv'

# based on the csv format Holvi.com creates
# WARNING: this is an ad hoc solution, so its not properly tested etc.
if defined?(ARGV[0]) && !ARGV[0].nil?
  rows = CSV.read(ARGV[0], {:headers => true, :header_converters => :symbol, :converters => :all} )
  puts rows.inspect
  last_receipt_number = nil
  rows.each do |row|
    continue = true
    # duplicate tickets should not happen
    unless Ticket.first({:ticket_code => row[:order_code]}).nil?
      puts "DUPLICATE TICKET"
      continue = false
    end
    # duplicate emails happen if customer has made two seperate
    # purchases with same email
    if !Customer.first({:email => row[:email]}).nil? && last_receipt_number != row[:receipt_number]
      puts "DUPLICATE EMAIL! Continuing. Check for:"
      puts row.inspect
    end
    if continue
      customer = Customer.first_or_create({
        :first_name => row[:first_name],
        :last_name => row[:last_name],
        :email => row[:email],
        :address => row[:street],
        :postal_code => row[:postal_code],
        :town => row[:city],
        :country => row[:country]
      });
      order = Order.first_or_create({
        :order_code => row[:receipt_number],
        :date => row[:date]
      });
      ticket = Ticket.first_or_create({
        :ticket_code => row[:order_code]
      });

      customer.orders << order
      order.tickets << ticket

      customer.save
      last_receipt_number = row[:receipt_number]
    end
  end
end
