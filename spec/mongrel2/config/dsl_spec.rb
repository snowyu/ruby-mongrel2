#!/usr/bin/env ruby

BEGIN {
	require 'pathname'
	basedir = Pathname.new( __FILE__ ).dirname.parent.parent.parent

	libdir = basedir + "lib"

	$LOAD_PATH.unshift( basedir ) unless $LOAD_PATH.include?( basedir )
	$LOAD_PATH.unshift( libdir ) unless $LOAD_PATH.include?( libdir )
}

require 'rspec'

require 'spec/lib/constants'
require 'spec/lib/helpers'

require 'mongrel2'
require 'mongrel2/config'


#####################################################################
###	C O N T E X T S
#####################################################################

describe Mongrel2::Config::DSL do

	include described_class

	before( :all ) do
		setup_logging( :fatal )
		Mongrel2::Config.configure( :configdb => ':memory:' )
	end

	before( :each ) do
		Mongrel2::Config.init_database!
	end

	after( :all ) do
		reset_logging()
	end


	RSpec::Matchers.define( :all_be_a ) do |mod|
		match do |collection|
			collection.all? {|obj| obj.is_a?(mod) }
		end
	end


	describe 'servers' do
		it "can generate a default server config using the 'server' declarative" do
			result = server '965A7196-99BC-46FA-945B-3478AE92BFB5'

			result.should be_a( Mongrel2::Config::Server )
			result.uuid.should == '965A7196-99BC-46FA-945B-3478AE92BFB5'
		end


		it "can generate a more-elaborate server config using the 'server' declarative with a block" do
			result = server '965A7196-99BC-46FA-945B-3478AE92BFB5' do
				name 'Intranet'
				chroot '/service/mongrel2'
				access_log '/var/log/access'
				error_log '/var/log/errors'
			end

			result.should be_a( Mongrel2::Config::Server )
			result.uuid.should == '965A7196-99BC-46FA-945B-3478AE92BFB5'
			result.name.should == 'Intranet'
			result.chroot.should == '/service/mongrel2'
			result.access_log.should == '/var/log/access'
			result.error_log.should == '/var/log/errors'
		end
	end


	describe 'hosts' do

		it "can add a host to a server config with the 'host' declarative" do
			result = server '965A7196-99BC-46FA-945B-3478AE92BFB5' do

				host 'localhost'

			end

			result.should be_a( Mongrel2::Config::Server )
			result.hosts.should have( 1 ).member
			host = result.hosts.first

			host.should be_a( Mongrel2::Config::Host )
			host.name.should == 'localhost'
		end

		it "can add several elaborately-configured hosts to a server via a block" do
			result = server '965A7196-99BC-46FA-945B-3478AE92BFB5' do

				host 'brillianttaste' do
					matching '*.brillianttasteinthefoodmouth.com'

					route '/images', directory( '/var/www/images' )
					route '/css', directory( '/var/www/css' )
					route '/vote', proxy( 'localhost', 6667 )
					route '/admin', handler(
						'tcp://127.0.0.1:9998',
						'D613E7EE-E2EB-4699-A200-5C8ECAB45D5E',
						'tcp://127.0.0.1:9997'
					)

					dir_handler = handler(
						'tcp://127.0.0.1:9996',
						'B7EFA46D-FEE4-432B-B80F-E8A9A2CC6FDB',
						'tcp://127.0.0.1:9995',
						'protocol' => 'tnetstring'
					)
					route '@directory', dir_handler
					route '/directory', dir_handler
				end

				host 'deveiate.org' do
					route '', directory( '/usr/local/deveiate/www/public' )
				end

			end

			result.should be_a( Mongrel2::Config::Server )
			result.hosts.should have( 2 ).members
			host1, host2 = result.hosts

			host1.should be_a( Mongrel2::Config::Host )
			host1.name.should == 'brillianttaste'
			host1.matching.should == '*.brillianttasteinthefoodmouth.com'
			host1.routes.should have( 6 ).members
			host1.routes.should all_be_a( Mongrel2::Config::Route )

			host1.routes[0].path.should == '/images'
			host1.routes[0].target.should be_a( Mongrel2::Config::Directory )
			host1.routes[0].target.base.should == '/var/www/images'

			host1.routes[1].path.should == '/css'
			host1.routes[1].target.should be_a( Mongrel2::Config::Directory )
			host1.routes[1].target.base.should == '/var/www/css'

			host1.routes[2].path.should == '/vote'
			host1.routes[2].target.should be_a( Mongrel2::Config::Proxy )
			host1.routes[2].target.addr.should == 'localhost'
			host1.routes[2].target.port.should == 6667

			host1.routes[3].path.should == '/admin'
			host1.routes[3].target.should be_a( Mongrel2::Config::Handler )
			host1.routes[3].target.send_ident.should == 'D613E7EE-E2EB-4699-A200-5C8ECAB45D5E'
			host1.routes[3].target.send_spec.should == 'tcp://127.0.0.1:9998'
			host1.routes[3].target.recv_ident.should == ''
			host1.routes[3].target.recv_spec.should == 'tcp://127.0.0.1:9997'

			host1.routes[4].path.should == '@directory'
			host1.routes[4].target.should be_a( Mongrel2::Config::Handler )
			host1.routes[4].target.send_ident.should == 'B7EFA46D-FEE4-432B-B80F-E8A9A2CC6FDB'
			host1.routes[4].target.send_spec.should == 'tcp://127.0.0.1:9996'
			host1.routes[4].target.recv_spec.should == 'tcp://127.0.0.1:9995'
			host1.routes[4].target.recv_ident.should == ''
			host1.routes[4].target.protocol.should == 'tnetstring'

			host1.routes[5].path.should == '/directory'
			host1.routes[5].target.should == host1.routes[4].target

			host2.should be_a( Mongrel2::Config::Host )
			host2.name.should == 'deveiate.org'
			host2.routes.should have( 1 ).member
			host2.routes.first.should be_a( Mongrel2::Config::Route )
		end


	end

	it "can generate the mongrel2.org config" do

		# the server to run them all 
		result = server '2f62bd5-9e59-49cd-993c-3b6013c28f05' do

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
					'54c6755b-9628-40a4-9a2d-cc82a816345e', 
				    'tcp://127.0.0.1:9998'
				) 

			    route '/handlertest', handler(
					'tcp://127.0.0.1:9997', 
					'34f9ceee-cd52-4b7f-b197-88bf2f0ec378', 
					'tcp://127.0.0.1:9996'
				) 

				# a sample proxy route 
				web_app_proxy = proxy( '127.0.0.1', 8080 ) 

		    	route '/chat/', web_app_proxy
		    	route '/', web_app_proxy

				# here's a sample directory 
				test_directory = directory(
					'tests/',
					:index_file => 'index.html',
					:default_ctype => 'text/plain'
				)

				route '/tests/', test_directory
		    	route '/testsmulti/(.*.json)', test_directory

				chat_demo_dir = directory(
					'examples/chat/static/', 
					:index_file => 'index.html', 
					:default_ctype => 'text/plain'
				)

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

	end
end

