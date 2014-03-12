module Heroics
  # Generate a static client that uses Heroics under the hood.  This is a good
  # option if you want to ship a gem or generate API documentation using Yard.
  def self.generate_client(module_name, schema, url, accept_header=nil)
    filename = File.dirname(__FILE__) + '/views/client.erb'
    eruby = Erubis::Eruby.new(File.read(filename))
    context = build_context(module_name, schema, url, accept_header)
    eruby.evaluate(context)
  end

  private

  def self.build_context(module_name, schema, url, accept_header)
    resources = []
    schema.resources.each do |resource_schema|
      links = []
      resource_schema.links.each do |link_schema|
        links << GeneratorLink.new(link_schema.name.gsub('-', '_'),
                                   link_schema.description,
                                   link_schema.parameter_details)
      end
      resources << GeneratorResource.new(resource_schema.name.gsub('-', '_'),
                                         resource_schema.description,
                                         links)
    end

    {module_name: module_name,
     url: url,
     accept_header: accept_header,
     description: schema.description,
     schema: MultiJson.encode(schema.schema),
     resources: resources}
  end

  class GeneratorResource
    attr_reader :name, :description, :links

    def initialize(name, description, links)
      @name = name
      @description = description
      @links = links
    end

    def class_name
      Heroics.camel_case(name)
    end
  end

  class GeneratorLink
    attr_reader :name, :description, :parameters

    def initialize(name, description, parameters)
      @name = name
      @description = description
      @parameters = parameters
    end

    def parameter_names
      @parameters.map do |info|
        info[:name]
      end.join(', ')
    end
  end

  def self.camel_case(text)
    return text if text !~ /_/ && text =~ /[A-Z]+.*/
    text = text.split('_').map{ |element| element.capitalize }.join
    [/^Ssl/, /^Http/, /^Xml/].each do |replace|
      text.sub!(replace) { |match| match.upcase }
    end
    text
  end
end
