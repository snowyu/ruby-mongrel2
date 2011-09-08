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

Mongrel2::Config.init_database!

# the server to run them all 
server '34D8E57C-3E91-4F24-9BBE-0B53C1827CB4' do

    access_log   "/logs/access.log"
    error_log    "/logs/error.log"
    chroot       "./"
    pid_file     "/run/mongrel2.pid"
    default_host "localhost"
    name         "main"
    port         8113

	# your main host 
	host "localhost" do

		route '/', directory( 'data/mongrel2/', 'bootstrap.html', 'text/html' )
		route '/source', directory( 'examples/', 'README.txt', 'text/plain' )

		# Handlers
    	route '/hello', handler( 'tcp://127.0.0.1:9999',  'helloworld-handler' ) 
    	route '/dump', handler( 'tcp://127.0.0.1:9997', 'request-dumper' ) 

	end

end

setting "zeromq.threads", 2

mkdir_p 'run'
mkdir_p 'logs'