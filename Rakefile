require "rake"
require "colorize"
require "fileutils"

@gemspec = 'archetype.gemspec'
@spec = Gem::Specification.load(@gemspec)
@ruby_version = '1.9.3'
@devnull = File.new("/dev/null").path
@version_without_revision = @spec.version.to_s.gsub(@revision_pattern = /\.[a-z0-9]{7}$/, '')
@docs = "./docs"

Dir.glob('tasks/*.rake').each { |r| import r }

# until we have something to actually do as a default,
# lets print out a list of available tasks (`rake -T` for the lazy)
task :default do
  puts %x[rake -T | grep -v RDoc]
end
