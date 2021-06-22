#!/usr/bin/env ruby

require 'optparse'
require 'yaml'

ARGV << '-h' if ARGV.empty?

OPTIONS = {}
OptionParser.new do |opts|
  opts.banner = '''Usage: kubectl eksporter <resource> <name>
Export resources and removes a pre-defined set of fields for later import

Export a specific resource with either of the following commands:
kubectl eksporter <resource> <name>
kubectl eksporter <resource>/<name>

Export all resources of one type with:
kubectl eksporter <resource>

Eksporter also supports piping resources:
kubectl get pod -o yaml <name> | kubectl eksporter

Some arguments that are supported by kubectl-get are also supported by eksporter.

Arguments for eksporter
'''

  opts.on("--keep field1,field2,field3", Array, "Keep fields that are marked for deletion")
  opts.on("-n", "--namespace namespace", "If present, the namespace scope for this CLI request")
  opts.on("-l", "--selector label", "Selector (label query) to filter on, supports '=', '==', and '!='.(e.g. -l key1=value1,key2=value2)")
end.parse!(into: OPTIONS)

def clean_resource(resource, keep)
  resource['metadata'].delete('annotations') unless keep.include?('annotations')
  resource['metadata'].delete('creationTimestamp') unless keep.include?('creationTimestamp')
  resource['metadata'].delete('generateName') unless keep.include?('generateName')
  resource['metadata'].delete('generation') unless keep.include?('generation')
  if resource['metadata'].has_key?('labels')
    resource['metadata'].delete('labels') if resource['metadata']['labels'].empty?
  end
  resource['metadata'].delete('namespace') unless keep.include?('namespace')
  resource['metadata'].delete('ownerReferences') unless keep.include?('ownerReferences')
  resource['metadata'].delete('resourceVersion') unless keep.include?('resourceVersion')
  resource['metadata'].delete('selfLink') unless keep.include?('selfLink')
  resource['metadata'].delete('managedFields') unless keep.include?('managedFields')
  resource['metadata'].delete('uid') unless keep.include?('uid')
  resource.delete('status') unless keep.include?('status')
  if resource.has_key?('spec')
    if resource['spec'].has_key?('clusterIP')
      resource['spec'].delete('clusterIP') unless keep.include?('clusterIP')
    end
  end
  resource
end

def parse_resources(resources, keep)
  if resources.has_key?('items')
    items = resources['items']
    if items.empty?
      puts "No resources found"
      exit
    end

    items.each do |resource|
      print YAML.dump(clean_resource(resource, keep))
    end
  else
    print YAML.dump(clean_resource(resources, keep))
  end
end

def main
  resources = nil
  if (not STDIN.tty? and not STDIN.closed?)
    input = ARGF.read
    resources = YAML.load(input)
  else
    args = ARGV.join(' ')
    cmd = "kubectl get #{args} -o yaml"
    cmd += " -n #{OPTIONS[:namespace]}" if OPTIONS.has_key?(:namespace)
    cmd += " -l #{OPTIONS[:selector]}" if OPTIONS.has_key?(:selector)
    output = `#{cmd}`

    if $?.success?
      resources = YAML.load(output)
    else
      print resources
      exit(1)
    end
  end

  parse_resources(resources, OPTIONS[:keep] || [])
end

main
