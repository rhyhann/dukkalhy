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

# The program
module  Fleow
  
  # This is the first step of the site generation.
  # This module should be used with the *folder* or *file* method,
  # and it will either return an array of all the elements (Array of Openstruct)
  # or the single element (Openstruct).
  # Some people would wonder why these methods are so splat. It's because I plan,
  # in order to take over the world, to add more content sources, in the future.
  # It's nevertheless not splat enough (TODO)
  module Parser
    
    def self.folder(path)
      # TODO: subfolder or folder method
      Dir.glob("#{path}/**/*.*").map! {|f| (file f)}
    end

    def self.file(path)
      yaml path, (File.read Dir.glob("#{path}*"))
    end

    def self.yaml(path, content)
      # The header
      header  = (YAML.load content).symbolize
      # The content. We just remove the header
      content.sub! /.*\-\-\-\n/im, ''
      parse path, header, content
    end

    def self.parse(full_path, params, content)
      # If it's the full path, we remove unneeded path content
      path = full_path.sub(/.*\/pages/, '/pages').split '/'
      # The file name parsing
      for_page   = /_?([a-zA-Z]*)_?(\d+)-(\d+)-(\d+)_(\w+)\.([a-zA-Z]+)/
      for_layout = /(\w+)\.(\w+)/
      if path[-1] =~ for_page
        params[:markers], params[:year]     , params[:month]    ,  \
            params[:day], params[:filetitle], params[:renderer] = \
            *(path[-1].scan for_page)[0]
        params[:markers] = params[:markers].split '_'
      elsif path[-1] =~ for_layout
        params[:filetitle], params[:renderer] = *(path[-1].scan for_layout)[0]
      end
      # The file name and pages/ are useless
      path.delete_at(-1)
      path.shift
      # The other params to add
      params[:folders] = path
      params[:content] = content
      
      Page.new(params)
    end
  end


  class Page
    attr_writer :rendered
    def initialize(params)
      @params = params
      @rendered = {}
    end
    def [](element)
      @params[element]
    end
    #def []=(element, value)
    #  @params[element] = value
    #end

    def rendered(name)
      @rendered[name] ||= render \
          :renderer => @params[:renderer], #TODO: customize renderers
          :page     => self,
          :name     => name,
          :content  => @params[name]
    end
    def method_missing(method, value = nil, *arguments)
      method = method.to_s
      method.to_s.split('').last == "=" ?
          @rendered[method.chomp.to_sym] = value :
          @rendered[method.to_sym]
    end
  end

  class Holder
    attr_reader :path, :rendered

    def initialize(path, &block)
      @path, @block, @rendered = path, block, false
      @@holders ||= []
      @@holders << self
    end

    def render()
      @rendered = @block.call
    end

    def rendered
      @rendered || @rendered = self.render
    end

    class << self
      include Enumerable
      def each
        (@@holders ||= []).each {|p| yield p}
      end
    end
  end


  module Renderer
    def render(page_or_params = {})
      p = page_or_params
      p.is_a?(Page) ?
        (send p[:renderer], p       , :content, p[:content]) :
        (send p[:renderer], p[:page], p[:name], p[:content])
    end


    def render_haml(page_or_content, name = nil, content = nil)
      poc = page_or_content
      name && content ?
        (poc.send("#{name}=", ::Haml::Engine.new(content).render(self))) :
        (::Haml::Engine.new(poc).render(self))
    end
    alias :haml :render_haml

    def render_raw(page_or_content, name = nil, content = nil)
      poc = page_or_content
      name && content ?
          (poc.send("#{name}=", content)) :
          poc
    end
    alias :raw :render_raw
  end

  module Writer
    def write_all
      ::Fleow::Holder.each do |h|
        File.open( File.join( SITE, 'site/', h.path), 'w') do |f|
          f.write(h.rendered)
        end
      end
    end
  end
end

include Fleow::Renderer
include Fleow::Writer
