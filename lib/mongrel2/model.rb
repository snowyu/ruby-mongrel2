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
	# 'validation_helpers', 'schema', and 'subclasses' Sequel plugins.
	# 
	class Model < Sequel::Model
		include Mongrel2::Loggable

		plugin :validation_helpers
		plugin :schema
		plugin :subclasses


		### Reset the database connection that all model objects will use to +newdb+, which should
		### be a Sequel::Database.
		def self::db=( newdb )
			super
			self.descendents.each do |subclass|
				Mongrel2.log.info "Resetting database connection for: %p to: %p" % [ subclass, newdb ]
				subclass.db = newdb
			end
		end

	end # class Model


	### Overridden version of Sequel.Model() that creates subclasses of Mongrel2::Model instead
	### of Sequel::Model.
	def self::Model( source )
		unless Sequel::Model::ANONYMOUS_MODEL_CLASSES.key?( source )
			anonclass = nil
		 	if source.is_a?( Sequel::Database )
				anonclass = Class.new( Mongrel2::Model )
				anonclass.db = source
			else
				anonclass = Class.new( Mongrel2::Model ).set_dataset( source )
			end

			Sequel::Model::ANONYMOUS_MODEL_CLASSES[ source ] = anonclass
		end

		return Sequel::Model::ANONYMOUS_MODEL_CLASSES[ source ]
	end

end # module Mongrel2
