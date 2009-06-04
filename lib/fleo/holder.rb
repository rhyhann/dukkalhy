module Fleo
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
