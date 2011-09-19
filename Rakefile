#!/usr/bin/env rake

begin
	require 'hoe'
rescue LoadError
	abort "This Rakefile requires 'hoe' (gem install hoe)"
end

# Work around borked RSpec support in this version
if Hoe::VERSION == '2.12.0'
	warn "Ignore warnings about not having rspec; it's a bug in Hoe 2.12.0"
	require 'rspec'
end

Hoe.plugin :mercurial
Hoe.plugin :signing

Hoe.plugins.delete :rubyforge

hoespec = Hoe.spec 'mongrel2' do
	self.readme_file = 'README.rdoc'
	self.history_file = 'History.rdoc'
	self.extra_rdoc_files << 'README.rdoc' << 'History.rdoc'
	self.spec_extras[:rdoc_options] = ['-t', 'Ruby-Mongrel2']

	self.developer 'Michael Granger', 'ged@FaerieMUD.org'

	self.dependency 'nokogiri',   '~> 1.5'
	self.dependency 'sequel',     '~> 3.26'
	self.dependency 'amalgalite', '~> 1.1'
	self.dependency 'tnetstring', '~> 0.3'
	self.dependency 'yajl-ruby',  '~> 0.8'
	self.dependency 'zmq',        '~> 2.1.4'

	self.dependency 'configurability', '~> 1.0', :developer
	self.dependency 'rspec',           '~> 2.4', :developer

	self.spec_extras[:licenses] = ["BSD"]
	self.require_ruby_version( '>= 1.9.2' )

	self.rdoc_locations << "deveiate:/usr/local/www/public/code/#{remote_rdoc_dir}"
end

ENV['VERSION'] ||= hoespec.spec.version.to_s

# Ensure the specs pass before checking in
task 'hg:precheckin' => :spec


# Rebuild the ChangeLog immediately before release
task :prerelease => [:check_manifest, :check_history, 'ChangeLog']


desc "Build a coverage report"
task :coverage do
	ENV["COVERAGE"] = 'yes'
	Rake::Task[:spec].invoke
end

