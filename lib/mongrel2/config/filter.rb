#!/usr/bin/env ruby

require 'tnetstring'

require 'mongrel2' unless defined?( Mongrel2 )
require 'mongrel2/config' unless defined?( Mongrel2::Config )

# Mongrel2 Filter configuration class
#
#   # Using the config DSL:
#   filter '/usr/local/lib/mongrel2/filters/null.so',
#       extensions: ["*.html", "*.txt"],
#       min_size: 1000
#
#   # Which is the same as:
#   Mongrel2::Config::Filter.create(
#       mame: '/usr/local/lib/mongrel2/filters/null.so',
#       settings: {
#         extensions: ["*.html", "*.txt"],
#         min_size: 1000
#       }
#
#   # Or:
#   server.add_filter(
#       mame: '/usr/local/lib/mongrel2/filters/null.so',
#       settings: {
#         extensions: ["*.html", "*.txt"],
#         min_size: 1000
#       })
#
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

