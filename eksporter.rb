#!/usr/bin/env ruby

require 'yaml'

def help
  puts '''Usage: kubectl eksporter <resource> <name>
Export resources and removes a pre-defined set of fields for later import

Export a specific resource with either of the following commands:
kubectl eksporter <resource> <name>
kubectl eksporter <resource>/<name>

Export all resources of one type with:
kubectl eksporter <resource>

Eksporter also supports piping resources:
kubectl get pod -o yaml <name> | kubectl eksporter

You can also use arguments that are supported by kubectl-get, such
as --namespace/-n, or --selector/-n. See kubectl get -h for more.
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
  resource['metadata'].delete('managedFields')
  resource['metadata'].delete('uid')
  resource.delete('status')
  if resource.has_key?('spec')
    if resource['spec'].has_key?('clusterIP')
      resource['spec'].delete('clusterIP')
    end
  end
  resource
end

def parse_resources(resources)
  if resources.has_key?('items')
    resources['items'].each do |resource|
      print YAML.dump(clean_resource(resource))
    end
  else
    print YAML.dump(clean_resource(resources))
  end
end

def main
  resources = nil
  if  (not STDIN.tty? and not STDIN.closed?) # ARGF.filename != "-" or
    input = ARGF.read
    resources = YAML.load(input)
  else
    parse_input

    args = ARGV.join(' ')
    output = `kubectl get #{args} -o yaml`

    if $?.success?
      resources = YAML.load(output)
    else
      print resource
      exit(1)
    end
  end

  parse_resources(resources)
end

main
