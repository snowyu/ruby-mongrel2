#!/usr/bin/env ruby

require 'mongrel2' unless defined?( Mongrel2 )
require 'mongrel2/config' unless defined?( Mongrel2::Config )

# Mongrel2 Directory (Dir) configuration class
class Mongrel2::Config::Directory < Mongrel2::Config( :directory )

	### As of Mongrel2/1.7.5:
	# CREATE TABLE directory (id INTEGER PRIMARY KEY,
	#    base TEXT,
	#    index_file TEXT,
	#    default_ctype TEXT,
	#    cache_ttl INTEGER DEFAULT 0);

end # class Mongrel2::Config::Directory

