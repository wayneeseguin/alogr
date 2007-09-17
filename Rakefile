require "rake"
require "rake/clean"
require "rake/gempackagetask"
require "rake/rdoctask"
require "rake/testtask"
require "fileutils"
include FileUtils
require "lib/alogr/version"

NAME = "alogr"
#REV = `svn info`[/Revision: (\d+)/, 1] rescue nil
REV = nil
VERS = ENV["VERSION"] || AlogR::VERSION::STRING + (REV ? ".#{REV}" : "")
CLEAN.include [
  "ext/aio_logger/*.{bundle,so,obj,pdb,lib,def,exp}", 
  "ext/aio_logger/Makefile", 
  "**/.*.sw?", 
  "*.gem", 
  ".config"
]
RDOC_OPTS = ["--quiet", "--title", "AlogR Reference", "--main", "README", "--inline-source"]

desc "Does a full compile, test run"
task :default => [:compile, :test]

desc "Compiles all extensions"
task :compile => [:aio_logger] do
  if Dir.glob(File.join("lib","aio_logger.*")).length == 0
    STDERR.puts "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
    STDERR.puts "Gem actually failed to build.  Your system is"
    STDERR.puts "NOT configured properly to build aio_logger."
    STDERR.puts "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
    exit(1)
  end
end

desc "Packages up AlogR."
task :package => [:clean]

desc "Releases packages for all AlogR packages and platforms."
task :release => [:package, :rubygems_win32]

desc "Run all the tests"
Rake::TestTask.new do | test_task |
  test_task.libs << "test"
  test_task.test_files = FileList["test/test_*.rb"]
  test_task.verbose = true
end

Rake::RDocTask.new do | rdoc |
  rdoc.rdoc_dir = "doc/rdoc"
  rdoc.options += RDOC_OPTS
  rdoc.main = "README"
  rdoc.rdoc_files.add ["README", "CHANGELOG", "COPYING", "lib/**/*.rb"]
end

spec =
Gem::Specification.new do | specification |
  specification.name = NAME
  specification.version = VERS
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
  Dir.glob("{bin,doc,test,lib,extras}/**/*") + 
  Dir.glob("ext/**/*.{h,c,rb,rl}") + 
  %w[ext/aio_logger/aio_logger.c] # needed because it's generated later

  specification.require_path = "lib"
  specification.extensions = FileList["ext/**/extconf.rb"].to_a
  specification.bindir = "bin"
end

Rake::GemPackageTask.new(spec) do | package |
  package.need_tar = true
  package.gem_spec = spec
end

extension = "aio_logger"
ext = "ext/aio_logger"
ext_so = "#{ext}/#{extension}.#{Config::CONFIG["DLEXT"]}"
ext_files = FileList[
  "#{ext}/*.c",
  "#{ext}/*.h",
  "#{ext}/*.rl",
  "#{ext}/extconf.rb",
  "#{ext}/Makefile",
  "lib"
] 

task "lib" do
  directory "lib"
end

desc "Builds just the #{extension} extension"
task extension.to_sym => ["#{ext}/Makefile", ext_so ]

file "#{ext}/Makefile" => ["#{ext}/extconf.rb"] do
  Dir.chdir(ext) do
    ruby "extconf.rb"
  end
end

file ext_so => ext_files do
  Dir.chdir(ext) do
    sh(PLATFORM =~ /win32/ ? "nmake" : "make")
  end
  cp ext_so, "lib"
end

task :install do
  sh %{rake package}
  sh %{sudo gem install pkg/#{NAME}-#{VERS}}
end

task :uninstall => [:clean] do
  sh %{sudo gem uninstall #{NAME}}
end

# Website tasks using webgen below

task :site => [:site_webgen, :site_rdoc]

task :site_webgen do
  sh %{pushd doc/site; webgen; ruby atom.rb > output/feed.atom; rsync -azv output/* rubyforge.org:/var/www/gforge-projects/mongrel/; popd }
end

task :site_rdoc do
  sh %{ rsync -azv doc/rdoc/* rubyforge.org:/var/www/gforge-projects/mongrel/rdoc/ }
end

desc "Upload website files to rubyforge"
task :website_upload do
  host = "#{rubyforge_username}@rubyforge.org"
  remote_dir = "/var/www/gforge-projects/#{PATH}/"
  local_dir = "website"
  sh %{rsync -aCv #{local_dir}/ #{host}:#{remote_dir}}
end

desc "Generate and upload website files"
task :website => [:site, :website_upload]

desc "Release the website and new gem version"
task :deploy => [:check_version, :website, :release] do
  puts "Remember to create SVN tag:"
  puts "svn copy svn+ssh://#{rubyforge_username}@rubyforge.org/var/svn/#{PATH}/trunk " +
  "svn+ssh://#{rubyforge_username}@rubyforge.org/var/svn/#{PATH}/tags/REL-#{VERS} "
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
  unless ENV["VERSION"] == VERS
    puts "Please update your version.rb to match the release version, currently #{VERS}"
    exit
  end
end


# Shies below

PKG_FILES = FileList[
  "test/**/*.{rb,html,xhtml}",
  "lib/**/*.rb",
  "ext/**/*.{c,rb,h,rl}",
  "CHANGELOG", "README", "Rakefile", "COPYING",
  "extras/**/*", "lib/aio_logger.so"
]

Win32Spec = Gem::Specification.new do | specification |
  specification.name = NAME
  specification.version = VERS
  specification.platform = Gem::Platform::WIN32
  specification.has_rdoc = false
  specification.extra_rdoc_files = ["README", "CHANGELOG", "COPYING"]
  specification.summary = "a threadsafe non-blocking asynchronous configurable logger for Ruby."
  specification.description = specification.summary
  specification.author = "Wayne E. Seguin"
  specification.email = "wayneeseguin at gmail dot com"
  specification.homepage = "alogr.rubyforge.org"
  
  specification.files = PKG_FILES
  
  specification.require_path = "lib"
  specification.extensions = []
  specification.bindir = "bin"
end

WIN32_PKG_DIR = "alogr-" + VERS

file WIN32_PKG_DIR => [:package] do
  sh "tar zxf pkg/#{WIN32_PKG_DIR}.tgz"
end

desc "Cross-compile the aio_logger extension for win32"
file "aio_logger_win32" => [WIN32_PKG_DIR] do
  cp "extras/mingw-rbconfig.rb", "#{WIN32_PKG_DIR}/ext/aio_logger/rbconfig.rb"
  sh "cd #{WIN32_PKG_DIR}/ext/aio_logger/ && ruby -I. extconf.rb && make"
  mv "#{WIN32_PKG_DIR}/ext/aio_logger/aio_logger.so", "#{WIN32_PKG_DIR}/lib"
end

desc "Build the binary RubyGems package for win32"
task :rubygems_win32 => ["aio_logger_win32"] do
  Dir.chdir("#{WIN32_PKG_DIR}") do
    Gem::Builder.new(Win32Spec).build
    verbose(true) {
      mv Dir["*.gem"].first, "../pkg/alogr-#{VERS}-mswin32.gem"
    }
  end
end

CLEAN.include WIN32_PKG_DIR
