#!/usr/bin/env ruby

BEGIN {
	require 'pathname'
	basedir = Pathname( __FILE__ ).dirname.parent
	libdir = basedir + 'lib'

	$LOAD_PATH.unshift( libdir.to_s )
}

require 'rubygems'
require 'mongrel2'
require 'mongrel2/config'

Mongrel::Config.configure( :configdb => 'config.sqlite' )
include Mongrel2::Config::DSL

server '965A7196-99BC-46FA-945B-3478AE92BFB5' {
    name 'Arrow Bootstrap'
    chroot '/var/www'
    access_log '/logs/access.log'
    error_log  '/logs/error.log'
    default_host 'localhost'
    pid_file '/run/mongrel2.pid'
    port 3667

    host 'localhost' {

		route '/static', directory( '/data/mongrel2' )
		route '/static', directory( '/data/mongrel2' ), :reversed => true
		route '/proxy', proxy( 'http://google.com/' )
		route '/admin', handler(
			'D613E7EE-E2EB-4699-A200-5C8ECAB45D5E',
			'tcp://127.0.0.1:9998',
			'tcp://127.0.0.1:9997'
		)

		dir_handler = handler(
			'B7EFA46D-FEE4-432B-B80F-E8A9A2CC6FDB',
			'tcp://127.0.0.1:9996',
			'tcp://127.0.0.1:9995',
			:protocol => 'tnetstring'
		)
		route '@directory', dir_handler
		route '/directory', dir_handler

	}

}

