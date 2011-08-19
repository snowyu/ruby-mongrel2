#!/usr/bin/env ruby

require 'mongrel2' unless defined?( Mongrel2 )
require 'mongrel2/config' unless defined?( Mongrel2::Config )

# Mongrel2 Proxy configuration class
class Mongrel2::Config::Proxy < Mongrel2::Config( :proxy )

	### As of Mongrel2/1.7.5:
	# CREATE TABLE proxy (id INTEGER PRIMARY KEY,
	#     addr TEXT,
	#     port INTEGER);

end # class Mongrel2::Config::Proxy

