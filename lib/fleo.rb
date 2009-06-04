%w(ostruct yaml).each {|lib| (require lib)}

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
module  Fleo
  
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
      yaml (File.read path)
    end

    def self.yaml(content)
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
      regular = /_?([a-zA-Z]*)_?(\d+)-(\d+)-(\d+)_(\w+)\.([a-zA-Z]+)/
      if path[-1] =~ regular
        params[:markers], params[:year]     , params[:month]    ,  \
            params[:day], params[:filetitle], params[:formatter] = \
            *(path[-1].scan regular)[0]
        params[:markers] = params[:markers].split '_'
      else
        raise ArgumentError, "Bad naming of #{full_path}"
      end
      # The file name and pages/ are useless
      path.delete_at(-1)
      path.shift
      # The other params to add
      params[:folders] = path
      params[:content] = content
      
      OpenStruct.new params
    end
  end


  module Holder

    # When holding a block, the first argument
    # is the array of all the pages, the second
    # is eventually the parent.
    # The only role of this is to create the template
    # variables.
    def self.add(name, parent = nil, &block)
      @blocks ?
          @blocks[name] = [block, parent] :
          @blocks       = {name => [block, parent]}
    end

  end
end
