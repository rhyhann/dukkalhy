%w(yaml).each {|lib| (require lib)}

# Ruby extensions
class Hash
  def symbolize
    inject({}) do |options, (key, value)|
      options[(key.to_sym rescue key) || key] = value
      options
    end
  end
end
class String
  def /(other)
    File.join File.expand_path(self), other.to_s
  end
end

# This context will be very useful later.
SELF = self
SELF_CLASS = class << self; self; end
SITE ||= File.dirname(__FILE__)/''


# The program
module Dukkhalhy
  
  module Parser
    def self.parse(folder)
      Dir.glob("#{folder}/**/*.*").map! do |full_path|
        # Separate the various params
        content = File.read Dir.glob "#{full_path}*"
        header  = (YAML.load content).symbolize
        content.sub! /.*\-\-\-\n/im, '' # Remove the yaml header
        path = full_path.sub(/.*\/pages/, '/pages').split('/'); path.shift
        filename = path.pop # Remove everything annoying from the path

        # Params attribution
        for_page   = /_?([a-zA-Z]*)_?(\d+)-(\d+)-(\d+)_(\w+)\.([a-zA-Z]+)/
        for_layout = /(\w+)\.(\w+)/ # These are the filename regexp for pages and layouts.
        if filename =~ for_page
          header[:markers], header[:year]     , header[:month]    ,  \
              header[:day], header[:filetitle], header[:renderer] = \
              *(filename.scan for_page)[0]
          header[:markers] = header[:markers].split '_'
        elsif filename =~ for_layout
          header[:filetitle], header[:renderer] = *(filename.scan for_layout)[0]
        end
        header[:folders] = path
        header[:content] = content
        Page.new(header)
    end
  end


  class Page
    attr_writer   :rendered
    attr_accessor :params
    def initialize(params)
      @params = params
      @rendered = {}
    end

    def rendered(name)
      @rendered[name] ||= render \
          :renderer => @params[:renderer], #TODO: customize renderers
          :page     => self,
          :name     => name,
          :content  => @params[name]
    end

    def method_missing(method, value = nil, *arguments)
      method.to_s.split('').last == "=" ?
          @rendered[method.chop.to_sym] = value :
          @rendered[method.to_sym]
    end

  end

  class Holder
    attr_reader :path, :dirs, :rendered

    def initialize(path, &block)
      @path, @block, @rendered = path, block, false
      @dirs = @path.split('/');@dirs.pop; @dirs = @dirs.join('/')
      @@holders ||= []
      @@holders << self
    end

    def rendered
      @rendered || @rendered = @block.call
    end

    def write(dest, type = 'w')
      FileUtils.mkdir_p(dest/h.dirs)
      File.open(dest/h.path, type) {|f| f.write(self.rendered)}
    end

    class << self
      include Enumerable
      def each() (@@holders ||= []).each {|p| yield p}; end
    end
  end


  module Renderer
    def render(page_or_params = {})
      p = page_or_params
      p.is_a?(Page) ?
        (send p[:renderer], p       , :content, p[:content]) :
        (send p[:renderer], p[:page], p[:name], p[:content])
    end

    def renderer(name, &block)
      rendering = Proc.new do |poc, name, content|
        poc.is_a?(Page) ?
            (poc.send "#{name}=", block.call(content)) :
            block.call(content || poc)
      end
      SELF_CLASS.class_eval do
        define_method :"render_#{name}", rendering
        define_method name, rendering
      end
    end
  end

  module Writer
    def write_all(dest)
      ::Dukkhaly::Holder.each {|h| h.write(dest)}
    end
  end
end

include Dukkhaly::Renderer
include Dukkhaly::Writer

renderer(:haml) {|c| ::Haml::Engine.new(c).render(self) }
renderer(:raw ) {|c| c}
