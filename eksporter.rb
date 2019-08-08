#!/usr/bin/env ruby

require 'yaml'

def help
  print '''Export resources and removes a pre-defined set of fields for later import

Export a specific resource with either of the following commands:
kubectl eksporter <resource> <name>
kubectl eksporter <resource>/<name>

Export all resources with:
kubectl eksporter <resource>
'''
end

def parse_input
  if ARGV.length == 0
    p "Too few arguments"
    help
    exit
  end
  if ARGV[0] =~ /-(h|-help)/
    help
    exit
  end
end

def clean_resource(resource)
  resource['metadata'].delete('annotations')
  resource['metadata'].delete('creationTimestamp')
  resource['metadata'].delete('generateName')
  resource['metadata'].delete('generation')
  if resource['metadata'].has_key?('labels')
    resource['metadata'].delete('labels') if resource['metadata']['labels'].empty?
  end
  resource['metadata'].delete('namespace')
  resource['metadata'].delete('ownerReferences')
  resource['metadata'].delete('resourceVersion')
  resource['metadata'].delete('selfLink')
  resource['metadata'].delete('uid')
  resource.delete('status')
  resource
end

def main
  parse_input

  args = ARGV.join(' ')
  resources = YAML.load(`kubectl get #{args} -o yaml`)

  if $?.success?
    if resources.has_key?('items')
      resources['items'].each do |resource|
        print YAML.dump(clean_resource(resource))
      end
    else
      print YAML.dump(clean_resource(resources))
    end

  else
    print resources
  end
end

main
