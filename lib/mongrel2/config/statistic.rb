#!/usr/bin/env ruby

require 'mongrel2' unless defined?( Mongrel2 )
require 'mongrel2/config' unless defined?( Mongrel2::Config )

# Mongrel2 configuration statistic class
class Mongrel2::Config::Statistic < Mongrel2::Config( :statistic )

	### As of Mongrel2/1.7.5:
	# CREATE TABLE statistic (id SERIAL, 
	#     other_type TEXT,
	#     other_id INTEGER,
	#     name text,
	#     sum REAL,
	#     sumsq REAL,
	#     n INTEGER,
	#     min REAL,
	#     max REAL,
	#     mean REAL,
	#     sd REAL,
	#     primary key (other_type, other_id, name));

end # class Mongrel2::Config::Statistic
