#!/usr/bin/env ruby

# The Mongrel config used by the examples. 

BEGIN {
	require 'pathname'
	basedir = Pathname( __FILE__ ).dirname.parent
	libdir = basedir + 'lib'

	$LOAD_PATH.unshift( libdir.to_s )
}

require 'rubygems'
require 'fileutils'
require 'mongrel2'
require 'mongrel2/config'

include FileUtils::Verbose

Mongrel2.log.level = Logger::INFO
Mongrel2::Config.configure( :configdb => 'examples.sqlite' )
include Mongrel2::Config::DSL

# the server to run them all
server 'admin-server' do

    name         'admin'
    default_host 'localhost'

    access_log   '/logs/admin-access.log'
    error_log    '/logs/admin-error.log'
    chroot       '/var/mongrel2/admin'
    pid_file     '/run/mongrel2-admin.pid'

	bind_addr    '127.0.0.1'
    port         8888

	# your main host
	host "localhost" do

		route '/', directory( 'data/mongrel2/admin/', 'console.html', 'text/html' )

	end

end

