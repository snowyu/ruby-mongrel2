#!/usr/bin/env ruby

require 'mongrel2' unless defined?( Mongrel2 )
require 'mongrel2/config' unless defined?( Mongrel2::Config )

# Mongrel2 Mimetype configuration class
class Mongrel2::Config::Mimetype < Mongrel2::Config( :mimetype )

	### As of Mongrel2/1.7.5:
	# CREATE TABLE mimetype (id INTEGER PRIMARY KEY,
	#   mimetype TEXT,
	#   extension TEXT);

end # class Mongrel2::Config::Mimetype

