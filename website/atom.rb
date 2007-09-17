require 'rubygems'
require 'atom/collection'
require 'find'
require 'yaml'
require 'redcloth'

$site ="http://alogr.rubyforge.org/" 

wayne = Atom::Author.new
wayne.name = "Wayne E. Seguin"
wayne.uri = $site
wayne.email = "wayneeNOSPAMseguin A-T gmailNOSPAM.com"

f = Atom::Feed.new
f.id = $site
f.authors << wayne

link = Atom::Link.new
link["href"] = $site + "/feed.atom"
link["rel"] = "self"
f.links << link
link = Atom::Link.new
link["href"] = $site
link["rel"] = "via"
f.links << link

f.title = "AlogR"
f.subtitle = "un-blocking the log"
f.updated = Time.now
f.generator = "atom-tools"
f.rights = "Copyright Wayne E. Seguin.  All rights reserved."

class Page
  attr_accessor :path
  attr_accessor :stat
  attr_accessor :uri
  attr_accessor :info

  def initialize(path)
    @path = path
    @stat = File.stat(path)
    @uri = $site + path.match(/^src(.*)\.page/)[1] + ".html"
    @info = YAML.load_file(path)
  end

  def <=>(other)
    other.stat.mtime <=> self.stat.mtime
  end

  def to_html
    if not @html
      content = open(path) { |f| f.read(1024) }
      content.gsub!(/^---.*---/m,"")
      content = content + "...\n\"Read more\":#{uri}"
      r = RedCloth.new(content)
      @html = r.to_html
    end

    @html
  end
end

pages = []

Find.find("src") do |path|
  if /.page$/ === path and !path.index("index.page")
    pages << Page.new(path)
  end
end

pages.sort!

pages[0 .. 30].each do |p|
  e = Atom::Entry.new
  e.id = p.uri
  e.title = p.info["title"]
  link = Atom::Link.new
  link["href"] = p.uri
  e.links << link
  e.updated = p.stat.mtime
  f.entries << e
end


puts f.to_s
