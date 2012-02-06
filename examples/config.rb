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
server '34D8E57C-3E91-4F24-9BBE-0B53C1827CB4' do

    name         'main'
    default_host 'www.example.com'

    access_log   '/logs/access.log'
    error_log    '/logs/error.log'
    chroot       '/var/mongrel2'
    pid_file     '/run/mongrel2.pid'

	bind_addr    '0.0.0.0'
    port         8113

	# your main host
	host 'www.example.com' do

		route '/', directory( 'data/mongrel2/', 'bootstrap.html', 'text/html' )
		route '/source', directory( 'examples/', 'README.txt', 'text/plain' )

		# Handlers
		route '/hello', handler( 'tcp://127.0.0.1:9999',  'helloworld-handler' )
		route '/dump', handler( 'tcp://127.0.0.1:9997', 'request-dumper' )

	end

	filter '/usr/local/lib/mongrel2/filters/null.so',
		extensions: ["*.html", "*.txt"],
		min_size: 1000

end

setting "zeromq.threads", 1

mkdir_p 'run'
mkdir_p 'logs'

