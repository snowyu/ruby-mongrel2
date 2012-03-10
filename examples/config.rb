#!/usr/bin/env ruby

# The Mongrel config used by the examples. Load it with:
#
#   m2sh.rb -c examples.sqlite load examples/config.rb
#

# samples server
server 'examples' do

	name         'Examples'
	default_host 'localhost'

	access_log   '/logs/access.log'
	error_log    '/logs/error.log'
	chroot       '/var/mongrel2'
	pid_file     '/run/mongrel2.pid'

	bind_addr    '127.0.0.1'
	port         8113

	# your main host
	host 'localhost' do

		route '/', directory( 'data/mongrel2/', 'bootstrap.html', 'text/html' )
		route '/source', directory( 'examples/', 'README.txt', 'text/plain' )

		# Handlers
		dumper = handler( 'tcp://127.0.0.1:9997', 'request-dumper', protocol: 'tnetstring' )
		route '/hello', handler( 'tcp://127.0.0.1:9999',  'helloworld-handler' )
		route '/dump', dumper
		route '/ws', handler( 'tcp://127.0.0.1:9995', 'ws-echo' )
		route '@js', dumper
		route '<xml', dumper

	end

end

setting "zeromq.threads", 1

