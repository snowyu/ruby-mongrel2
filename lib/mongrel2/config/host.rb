#!/usr/bin/env ruby

require 'mongrel2' unless defined?( Mongrel2 )
require 'mongrel2/config' unless defined?( Mongrel2::Config )

# Mongrel2 Host configuration class
class Mongrel2::Config::Host < Mongrel2::Config( :host )

	### As of Mongrel2/1.7.5:
	# CREATE TABLE host (id INTEGER PRIMARY KEY, 
	#     server_id INTEGER,
	#     maintenance BOOLEAN DEFAULT 0,
	#     name TEXT,
	#     matching TEXT);

	one_to_many :routes

end # class Mongrel2::Config::Host

