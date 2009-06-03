
# The main Fleo class
# This is just a placeholder.
# Here is how fleo works :
#  - For each object inside _pages
#    = If it's a draft
#      - Just save the name of it in the object with the "draft" state
#      - Include it in the html report
#    = Else
#      - It will see which pageholders contains it, including the self page,
#        which is _always_ rendered
#        = How to guess pageholders ?
#          There are two types of page holders:
#          - outside - guessed with the directories:
#            _pages/foo/bar/page will have /, foo and bar as category
#            placeholders
#          - inside  - guessed with the attributes:
#            each field of the tag attribute will be a tag placeholder
#          A thild one may be added, the special one:
#          - self - may just contain the object, rendered with the object's
#            categoly template
#      - When the placeholders are determined, with their paths:
#        = Invoke the relative template, with the object, generate it and 
#          put it in the _site
#        = How to generate paths ?
#          It's all about the object's template path, guy !
# NB: This short introduction has been made for me. If I let this in the 
# version 1 or more, please contact me so I rewrite this to a more... human
# explication, n'est-ce pas ?
#
#

%w(
   rubygems ostruct
   yaml
  ).each {|lib| (require lib)}

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
  def remove!(pattern)
    replace (self.sub pattern, '')
  end
end

Dir.glob(File.dirname(__FILE__) + "/fleo/*.rb") {|file| (require file) }
