#!/usr/bin/env ruby

require 'etc'
require 'socket'

require 'mongrel2' unless defined?( Mongrel2 )
require 'mongrel2/config' unless defined?( Mongrel2::Config )

# Mongrel2 configuration Log class
class Mongrel2::Config::Log < Mongrel2::Config( :log )

	### As of Mongrel2/1.7.5:
	# CREATE TABLE log(id INTEGER PRIMARY KEY,
	#     who TEXT,
	#     what TEXT,
	#     location TEXT,
	#     happened_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
	#     how TEXT,
	#     why TEXT);

	### Log an entry to the commit log with the given +what+, +why+, +where+, and +how+ values
	### and return it after it's saved.
	def self::log_action( what, why=nil, where=nil, how=nil )
		where ||= Socket.gethostname
		how ||= File.basename( $0 )

		who = Etc.getlogin

		return self.create(
			who:      who,
			what:     what,
			location: where,
			how:      how,
			why:      why
		)
	end



	### Stringify the log entry and return it.
	def to_s
		# 2011-09-09 19:35:40 [who] @where how: what (why)
		return "%{happened_at} [%{who}] @%{location} %{how}: %{what} (%{why})" % self.values
	end

end # class Mongrel2::Config::Log
