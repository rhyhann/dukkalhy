require File.join(File.dirname(__FILE__), "spec_helper.rb")
describe "Parser" do
  before do
    @path = "_pages/ab/cd/ef/_draft_2009-09-31_la_grande_messe_de_l_invraisemblable.markdown"
    @header = <<-YAML
title: Boarf, peut-être...
foo: bar
---
YAML
    @content = <<-YAML
Je suis un con carabiné.
Enfin, je crois.
YAML
    @yaml = @header + @content
    @params = {
        :title => "Boarf, peut-être...",
        :foo   => "bar",
        :folders => %w(ab cd ef),
        :markers => ["draft"],
        :year => "2009" ,
        :month => "09",
        :day => "31",
        :filetitle => "la_grande_messe_de_l_invraisemblable",
        :formatter => "markdown",
        :content => @content
    }

    @parsed = OpenStruct.new(@params)
  end

  it "renders everything good" do
    a = Parser.parse(@path, @params, @content)
    p a.content

    a.should == @parsed
  end
end
