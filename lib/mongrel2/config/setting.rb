#!/usr/bin/env ruby

require 'mongrel2' unless defined?( Mongrel2 )
require 'mongrel2/config' unless defined?( Mongrel2::Config )

# Mongrel2 Setting configuration class
class Mongrel2::Config::Setting < Mongrel2::Config( :setting )

	### As of Mongrel2/1.7.5:
	# CREATE TABLE setting (id INTEGER PRIMARY KEY, 
	# 	key TEXT, 
	# 	value TEXT);

end # class Mongrel2::Config::Setting

