#!/usr/bin/env ruby

require 'mongrel2' unless defined?( Mongrel2 )
require 'mongrel2/config' unless defined?( Mongrel2::Config )

# Mongrel2 Route configuration class
class Mongrel2::Config::Route < Mongrel2::Config( :route )

	### As of Mongrel2/1.7.5:
	# CREATE TABLE route (id INTEGER PRIMARY KEY,
	#     path TEXT,
	#     reversed BOOLEAN DEFAULT 0,
	#     host_id INTEGER,
	#     target_id INTEGER,
	#     target_type TEXT);

	### Doesn't work; load-order issues?
	# plugin :single_table_inheritance, :target_type, 
	# 	:model_map => {
	# 		'dir' => 'Mongrel2::Config::DirectoryRoute',
	# 		'proxy' => 'Mongrel2::Config::ProxyRoute',
	# 		'handler' => 'Mongrel2::Config::HandlerRoute'
	# 	}

	def target
		case self.target_type
		when 'dir'
			return Mongrel2::Config::Directory[ self.target_id ]
		when 'proxy'
			return Mongrel2::Config::Proxy[ self.target_id ]
		when 'handler'
			return Mongrel2::Config::Handler[ self.target_id ]
		else
			raise ArgumentError, "unknown target type %p" % [ self.target_type ]
		end
	end

end # class Mongrel2::Config::Route

