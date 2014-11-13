class Order
  include DataMapper::Resource
  belongs_to :customer
  has n, :tickets

  property :id, Serial # An auto-increment integer key
  property :order_code, String # Receipt number in Holvi
  property :date, DateTime
end

class Ticket
  include DataMapper::Resource
  belongs_to :order

  property :id, Serial
  property :ticket_code, String # Order code in Holvi (confusing, I know...)
  property :checked_in, Boolean, :default  => false
end

class Customer
  include DataMapper::Resource
  has n, :orders

  property :id, Serial
  property :first_name, String
  property :last_name, String
  property :email, String
  property :address, String
  property :postal_code, String
  property :town, String
  property :country, String
end

DataMapper.finalize
