#!/usr/bin/env ruby

require 'mongrel2' unless defined?( Mongrel2 )
require 'mongrel2/config' unless defined?( Mongrel2::Config )

# Mongrel2 Handler configuration class
class Mongrel2::Config::Handler < Mongrel2::Config( :handler )

	### As of Mongrel2/1.7.5:
	# CREATE TABLE handler (id INTEGER PRIMARY KEY,
	#     send_spec TEXT, 
	#     send_ident TEXT,
	#     recv_spec TEXT,
	#     recv_ident TEXT,
	#    raw_payload INTEGER DEFAULT 0,
	#    protocol TEXT DEFAULT 'json');

end # class Mongrel2::Config::Handler

