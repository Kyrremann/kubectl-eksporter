#!/usr/bin/env ruby

require 'optparse'
require 'yaml'

OPTIONS = {}
OPTIONPARSER = OptionParser.new do |opts|
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
  opts.on("--drop field1,field2,field3", Array, "Drop fields that normally are spared")
  opts.on("-n", "--namespace namespace", String, "If present, the namespace scope for this CLI request")
  opts.on("-l", "--selector label", String, "Selector (label query) to filter on, supports '=', '==', and '!='.(e.g. -l key1=value1,key2=value2)")
end

def delete_field(resource, fields)
  field = fields.shift
  if fields.empty?
    if resource.kind_of?(Array)
      resource.each do |res|
        delete_field(res, [field])
      end
    else
      resource.delete(field)
    end
  else
    delete_field(resource[field], fields)
  end
end

def clean_resource(resource, removable_fields)
  removable_fields.each do |field|
    fields = field.split('.')
    delete_field(resource, fields)
  end

  resource
end

def parse_resources(resources, removable_fields)
  if resources.has_key?('items')
    items = resources['items']
    if items.empty?
      puts "No resources found"
      exit
    end
  else
    items = [resources]
  end

  items.each do |resource|
    print YAML.dump(clean_resource(resource, removable_fields))
  end
end

def main
  resources = nil
  if (not STDIN.tty? and not STDIN.closed?)
    input = ARGF.read
    resources = YAML.load(input)
  else
    ARGV << '-h' if ARGV.empty?
    OPTIONPARSER.parse!(into: OPTIONS)

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

  removable_fields = [
    'metadata.annotations',
    'metadata.creationTimestamp',
    'metadata.generateName',
    'metadata.generation',
    'metadata.labels',
    'metadata.namespace',
    'metadata.ownerReferences',
    'metadata.resourceVersion',
    'metadata.selfLink',
    'metadata.managedFields',
    'metadata.uid',
    'spec.clusterIP',
    'status']
  removable_fields |= (OPTIONS[:drop] || [])
  removable_fields = removable_fields - (OPTIONS[:keep] || [])

  parse_resources(resources, removable_fields)
end

main
