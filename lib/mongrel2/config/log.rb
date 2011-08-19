#!/usr/bin/env ruby

require 'mongrel2' unless defined?( Mongrel2 )
require 'mongrel2/config' unless defined?( Mongrel2::Config )

# Mongrel2 configuration Log class
class Mongrel2::Config::Log < Mongrel2::Config( :log )

	### As of Mongrel2/1.7.5:
	# CREATE TABLE log(id INTEGER PRIMARY KEY,
	#     who TEXT,
	#     what TEXT,
	#     location TEXT,
	#     happened_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
	#     how TEXT,
	#     why TEXT);

end # class Mongrel2::Config::Log
