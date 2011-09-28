#!/usr/bin/env ruby

require 'mongrel2' unless defined?( Mongrel2 )
require 'mongrel2/config' unless defined?( Mongrel2::Config )


# Mongrel2 Server configuration class
class Mongrel2::Config::Server < Mongrel2::Config( :server )

	### As of Mongrel2/1.7.5:
	# CREATE TABLE server (id INTEGER PRIMARY KEY,
	#     uuid TEXT,
	#     access_log TEXT,
	#     error_log TEXT,
	#     chroot TEXT DEFAULT '/var/www',
	#     pid_file TEXT,
	#     default_host TEXT,
	#     name TEXT DEFAULT '',
	#     bind_addr TEXT DEFAULT "0.0.0.0",
	#     port INTEGER,
	#     use_ssl INTEGER default 0);

	one_to_many :hosts

	##
	# Look up a server by its +uuid+.
	# :singleton-method: by_uuid
	# :call-seq:
	#    by_uuid( uuid )
	def_dataset_method( :by_uuid ) {|uuid| filter(:uuid => uuid).first }


	#
	# :section: Validation Callbacks
	#

	### Sequel validation callback: add errors if the record is invalid.
	def validate
		self.validates_presence [ :access_log, :error_log, :pid_file, :default_host, :port ],
			message: 'is missing or nil'
	end



	### DSL methods for the Server context besides those automatically-generated from its
	### columns.
	module DSLMethods

		### Add a Mongrel2::Config::Host to the Server object with the given +hostname+. If a
		### +block+ is specified, it can be used to further configure the Host.
		def host( name, &block )
			self.target.save( :validate => false )

			Mongrel2.log.debug "Host [%s] (block: %p)" % [ name, block ]
			adapter = Mongrel2::Config::DSL::Adapter.new( Mongrel2::Config::Host,
				:name => name, :matching => name )
			adapter.instance_eval( &block ) if block
			self.target.add_host( adapter.target )
		end


	end # module DSLMethods

end # class Mongrel2::Config::Server

