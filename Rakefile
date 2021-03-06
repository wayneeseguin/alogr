require "rake"
require "rake/clean"
require "rake/gempackagetask"
require "rake/rdoctask"
require "rake/testtask"
require "fileutils"
require "yaml"
require "lib/alogr"

include FileUtils

GEM_NAME = "alogr"
#REV = `svn info`[/Revision: (\d+)/, 1] rescue nil
REV = nil
#GEM_VERSION = ENV["VERSION"] || AlogR::VERSION::STRING + (REV ? ".#{REV}" : "")
GEM_VERSION = AlogR::Version# + (REV ? ".#{REV}" : "")
#CLEAN.include [
#  "ext/aio_logger/*.{bundle,so,obj,pdb,lib,def,exp}", 
#  "ext/aio_logger/Makefile", 
#  "**/.*.sw?", 
#  "*.gem", 
#  ".config"
#]
RDOC_OPTS = ["--quiet", "--title", "AlogR Reference", "--main", "README", "--inline-source"]

@config_file = "~/.rubyforge/user-config.yml"
@config = nil
def rubyforge_username
  unless @config
    begin
      @config = YAML.load(File.read(File.expand_path(@config_file)))
    rescue
      puts <<-EOS
ERROR: No rubyforge config file found: #{@config_file}"
Run 'rubyforge setup' to prepare your env for access to Rubyforge
 - See http://newgem.rubyforge.org/rubyforge.html for more details
      EOS
      exit
    end
  end
  @rubyforge_username ||= @config["username"]
end

#desc "Does a full compile, test run"
#task :default => [:compile, :test]

#desc "Compiles all extensions"
#task :compile => [:aio_logger] do
#  if Dir.glob(File.join("lib","aio_logger.*")).length == 0
#    STDERR.puts "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
#    STDERR.puts "Gem actually failed to build.  Your system is"
#    STDERR.puts "NOT configured properly to build aio_logger."
#    STDERR.puts "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
#    exit(1)
#  end
#end

desc "Packages up AlogR."
task :package# => [:clean]

desc "Releases packages for all AlogR packages and platforms."
task :release => [:package]#, :rubygems_win32]

#desc "Run all the specs"
#Rake::SpecTask.new do | spec_task |
  #spec_task.libs << "spec"
  #spec_task.spec_files = FileList["spec/*_spec.rb"]
  #spec_task.spec_opts = ["--color", "--diff"]
#end

Rake::RDocTask.new do | rdoc |
  rdoc.rdoc_dir = "doc/rdoc"
  rdoc.options += RDOC_OPTS
  rdoc.main = "README"
  rdoc.rdoc_files.add ["README", "CHANGELOG", "COPYING", "lib/**/*.rb"]
end

spec =
Gem::Specification.new do | specification |
  specification.name = GEM_NAME
  specification.version = GEM_VERSION
  specification.platform = Gem::Platform::RUBY
  specification.has_rdoc = true
  specification.rdoc_options += RDOC_OPTS
  specification.extra_rdoc_files = ["README", "CHANGELOG", "COPYING"]
  specification.summary = "a threadsafe non-blocking asynchronous configurable logger for Ruby."
  specification.description = specification.summary
  specification.author = "Wayne E. Seguin"
  specification.email = "wayneeseguin at gmail dot com"
  specification.homepage = "alogr.rubyforge.org"
  
  specification.files = %w(COPYING README Rakefile) +
  Dir.glob("{bin,doc,test,lib,extras}/**/*")# + 
  #Dir.glob("ext/**/*.{h,c,rb,rl}") + 
  #%w[ext/aio_logger/aio_logger.c] # needed because it's generated later

  specification.require_path = "lib"
  #specification.extensions = FileList["ext/**/extconf.rb"].to_a
  specification.bindir = "bin"
end

Rake::GemPackageTask.new(spec) do | package |
  package.need_tar = true
  package.gem_spec = spec
end

#extension = "aio_logger"
#ext = "ext/aio_logger"
#ext_so = "#{ext}/#{extension}.#{Config::CONFIG["DLEXT"]}"
#ext_files = FileList[
  #"#{ext}/*.c",
  #"#{ext}/*.h",
  #"#{ext}/*.rl",
  #"#{ext}/extconf.rb",
  #"#{ext}/Makefile",
  #"lib"
#] 

task "lib" do
  directory "lib"
end

#desc "Builds just the #{extension} extension"
#task extension.to_sym => ["#{ext}/Makefile", ext_so ]

#file "#{ext}/Makefile" => ["#{ext}/extconf.rb"] do
#  Dir.chdir(ext) do
#    ruby "extconf.rb"
#  end
#end

#file ext_so => ext_files do
#  Dir.chdir(ext) do
#    sh(PLATFORM =~ /win32/ ? "nmake" : "make")
#  end
#  cp ext_so, "lib"
#end

task :install do
  sh %{rake package}
  sh %{sudo gem install pkg/#{GEM_NAME}-#{GEM_VERSION}}
end

task :uninstall do#=> [:clean] do
  sh %{sudo gem uninstall #{GEM_NAME}}
end

#
# Website tasks via webgen
#

desc "Generate and upload website files"
task :website => [:generate_website, :upload_website, :generate_rdoc, :upload_rdoc]

task :generate_website do
  # ruby atom.rb > output/feed.atom
  sh %{pushd website; webgen; popd }
end

task :generate_rdoc do
  sh %{rake rdoc}
end

desc "Upload website files to rubyforge"
task :upload_website do
  sh %{rsync -avz website/output/ #{rubyforge_username}@rubyforge.org:/var/www/gforge-projects/#{GEM_NAME}/}
end

desc "Upload rdoc files to rubyforge"
task :upload_rdoc do
  sh %{rsync -avz doc/rdoc/ #{rubyforge_username}@rubyforge.org:/var/www/gforge-projects/#{GEM_NAME}/rdoc}
end

desc "Release the website and new gem version"
task :deploy => [:check_version, :website, :release] do
  puts "Remember to create SVN tag:"
  puts "svn copy svn+ssh://#{rubyforge_username}@rubyforge.org/var/svn/#{PATH}/trunk " +
  "svn+ssh://#{rubyforge_username}@rubyforge.org/var/svn/#{PATH}/tags/REL-#{GEM_VERSION} "
  puts "Suggested comment:"
  puts "Tagging release #{CHANGES}"
end

desc "Runs tasks website_generate and install_gem as a local deployment of the gem"
task :local_deploy => [:website_generate, :install_gem]

task :check_version do
  unless ENV["VERSION"]
    puts "Must pass a VERSION=x.y.z release version"
    exit
  end
  unless ENV["VERSION"] == GEM_VERSION
    puts "Please update your version.rb to match the release version, currently #{GEM_VERSION}"
    exit
  end
end
