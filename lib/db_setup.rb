require 'data_mapper'
DataMapper.setup(:default, "sqlite://#{File.expand_path('db/orders.db')}")
require './db/models.rb'

require 'dm-migrations'

DataMapper.auto_upgrade!
