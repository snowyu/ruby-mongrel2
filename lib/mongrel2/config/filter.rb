#!/usr/bin/env ruby

require 'tnetstring'

require 'mongrel2' unless defined?( Mongrel2 )
require 'mongrel2/config' unless defined?( Mongrel2::Config )

# Mongrel2 Host configuration class
class Mongrel2::Config::Filter < Mongrel2::Config( :filter )

	### As of Mongrel2/1.7.5:
	# CREATE TABLE filter (id INTEGER PRIMARY KEY,
	#     server_id INTEGER,
	#     name TEXT,
	#     settings TEXT);

	many_to_one :server


	# Serialize the settings column as TNetStrings
	plugin :serialization, :tnetstring, :settings

end # class Mongrel2::Config::Filter

