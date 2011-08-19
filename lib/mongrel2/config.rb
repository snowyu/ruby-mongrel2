#!/usr/bin/ruby

require 'sequel'

# Rude hack to stop Sequel::Model from complaining if it's subclassed before
# the first database connection is established. Ugh.
Sequel::Model.db = Sequel.sqlite if Sequel::DATABASES.empty?

require 'mongrel2' unless defined?( Mongrel2 )
require 'mongrel2/mixins'

module Mongrel2

	# The base Mongrel2 database-backed configuration class. It's a subclass of Sequel::Model, so
	# you'll first need to be familiar with Sequel (http://sequel.rubyforge.org/) and 
	# especially its Sequel::Model ORM. 
	#
	# See the Sequel::Plugins::InlineMigrations module and the documentation for the
	# 'validation_helpers' and 'subclasses' Sequel plugins.
	# 
	class Config < Sequel::Model
		include Mongrel2::Loggable

		plugin :validation_helpers
		plugin :subclasses

		# Configuration defaults
		DEFAULTS = {
			:configdb => Mongrel2::DEFAULT_CONFIG_URI,
		}

		# Register this class as configurable if Configurability is loaded.
		if defined?( Configurability )
			extend Configurability
			config_key :mongrel2
		end


		### Configurability API -- called when the configuration is loaded with the
		### 'mongrel2' section of the config file if there is one. This method can also be used
		### without Configurability by passing an object that can be merged with
		### Mongrel2::Config::DEFAULTS.
		def self::configure( config={} )
			config = DEFAULTS.merge( config )
			self.db = Sequel.sqlite( config[:configdb] ) if config[ :configdb ]
		end


		### Reset the database connection that all model objects will use to +newdb+, which should
		### be a Sequel::Database.
		def self::db=( newdb )
			super
			self.descendents.each do |subclass|
				Mongrel2.log.info "Resetting database connection for: %p to: %p" % [ subclass, newdb ]
				subclass.db = newdb
			end
		end


		### Return the Array of currently-configured servers in the config database as
		### Mongrel2::Config::Server objects.
		def self::servers
			return Mongrel2::Config::Server.all
		end

	end # class Config


	### Overridden version of Sequel.Model() that creates subclasses of Mongrel2::Model instead
	### of Sequel::Model.
	def self::Config( source )
		unless Sequel::Model::ANONYMOUS_MODEL_CLASSES.key?( source )
			anonclass = nil
		 	if source.is_a?( Sequel::Database )
				anonclass = Class.new( Mongrel2::Config )
				anonclass.db = source
			else
				anonclass = Class.new( Mongrel2::Config ).set_dataset( source )
			end

			Sequel::Model::ANONYMOUS_MODEL_CLASSES[ source ] = anonclass
		end

		return Sequel::Model::ANONYMOUS_MODEL_CLASSES[ source ]
	end

	require 'mongrel2/config/directory'
	require 'mongrel2/config/handler'
	require 'mongrel2/config/host'
	require 'mongrel2/config/proxy'
	require 'mongrel2/config/route'
	require 'mongrel2/config/server'
	require 'mongrel2/config/setting'
	require 'mongrel2/config/log'
	require 'mongrel2/config/statistic'

end # module Mongrel2

