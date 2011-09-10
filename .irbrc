#!/usr/bin/env ruby
# vim: set nosta noet ts=4 sw=4:

BEGIN {
    require 'pathname'
	$LOAD_PATH.unshift( Pathname.new( __FILE__ ).dirname + 'lib' )
}

begin
	require 'configurability'
	require 'mongrel2'
	require 'mongrel2/config'

	Mongrel2::Config.configure
	include Mongrel2::Config::DSL
rescue Exception => err
	$stderr.puts "Mongrel2 failed to load: %p: %s" % [ err.class, err.message ]
	$stderr.puts( err.backtrace )
end

