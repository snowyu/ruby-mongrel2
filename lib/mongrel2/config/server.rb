#!/usr/bin/env ruby

require 'mongrel2' unless defined?( Mongrel2 )
require 'mongrel2/config' unless defined?( Mongrel2::Config )


# Mongrel2 Server configuration class
class Mongrel2::Config::Server < Mongrel2::Config( :server )

	### As of Mongrel2/1.7.5:
	# CREATE TABLE server (id INTEGER PRIMARY KEY,
	#     uuid TEXT,
	#     access_log TEXT,
	#     error_log TEXT,
	#     chroot TEXT DEFAULT '/var/www',
	#     pid_file TEXT,
	#     default_host TEXT,
	#     name TEXT DEFAULT '',
	#     bind_addr TEXT DEFAULT "0.0.0.0",
	#     port INTEGER,
	#     use_ssl INTEGER default 0);

	one_to_many :hosts

end # class Mongrel2::Config::Server

