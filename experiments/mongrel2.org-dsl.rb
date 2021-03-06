#!/usr/bin/env ruby

require 'mongrel2/config'
include Mongrel2::Config::DSL

# The mongrel.org config from the manual expressed using the DSL
# instead of the m2sh config file. Diffs of the database dumps look
# equivalent except for whitespace, route insertion order (not sure
# if this matters), and the commit log entry. I'll add commit log
# stuff soon.

# the server to run them all 
server '2f62bd5-9e59-49cd-993c-3b6013c28f05' do

    access_log   "/logs/access.log"
    error_log    "/logs/error.log"
    chroot       "./"
    pid_file     "/run/mongrel2.pid"
    default_host "mongrel2.org"
    name         "main"
    port         6767

	# your main host 
	host "mongrel2.org" do

		# a sample of doing some handlers 
    	route '@chat', handler(
			'tcp://127.0.0.1:9999', 
			'54c6755b-9628-40a4-9a2d-cc82a816345e'
		) 

	    route '/handlertest', handler(
			'tcp://127.0.0.1:9997', 
			'34f9ceee-cd52-4b7f-b197-88bf2f0ec378'
		) 

		# a sample proxy route 
		web_app_proxy = proxy( '127.0.0.1', 8080 ) 

    	route '/chat/', web_app_proxy
    	route '/', web_app_proxy

		# here's a sample directory 
		test_directory = directory( 'tests/', 'index.html', 'text/plain' )

		route '/tests/', test_directory
    	route '/testsmulti/(.*.json)', test_directory

		chat_demo_dir = directory( 'examples/chat/static/', 'index.html', 'text/plain' )

		route '/chatdemo/', chat_demo_dir
		route '/static/', chat_demo_dir

		route '/mp3stream', handler( 
			'tcp://127.0.0.1:9995', 
			'53f9f1d1-1116-4751-b6ff-4fbe3e43d142', 
			'tcp://127.0.0.1:9994'
		) 
	end

end

settings(
	"zeromq.threads"         => 1,
	"upload.temp_store"      => "/home/zedshaw/projects/mongrel2/tmp/upload.XXXXXX", 
	"upload.temp_store_mode" => "0666" 
)

