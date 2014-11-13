QR Check In Server
---------------------
- Built using [QRCheckIn stub server](http://skeary.github.io/QRCheckIn/stub_server.html) as a base.
- Using an SQlite3 database
- Contains a very basic implementation to parse order data from a product in Holvi.com shop (csv2db.rb)

## To run locally:
```
# clone from git

# dependencies
sudo apt-get install sqlite3
sudo apt-get install ruby
# on mac: brew install ruby
sudo apt-get install imagemagick
# on mac: brew install imagemagick

sudo gem install bundler
sudo gem install sinatra

# bundling
bundle

# build database
bundle exec ruby lib/db_setup.rb

# run server
bundle exec ruby server.rb
```
