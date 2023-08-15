#!/usr/bin/env ruby

# frozen_string_literal: true

require 'optimist'
require 'colorize'
require './lib/command'
require './lib/common'

commands = {}
subcommands = []
flags = {}

Dir[File.expand_path('./commands/*.rb', __dir__)].sort.each do |path|
  require path
  base = File.basename(path, '.rb')
  command = Kernel.const_get(base)
  subcommands.push(command.command)
  command.flags.each do |flag|
   flag_key = flag[:flag]
   flags[flag_key] = flag unless flags.key?(flag_key)    
  end
  commands[command.command] = command
end

Dir[File.expand_path('./actions/*.rb', __dir__)].sort.each { |path| require path }

# Application message to display as banner in the help menu.
banner = <<~BANNER

  Usage: ./pubdlib.rb [subcommand] --flag flag

  Examples:

    $ ./pubdlib.rb publish -i fales_mss222_cuid28860 -e config.local.json
    $ ./pubdlib.rb publish -i fales_mss222_cuid28861 -e config.local.json
    $ ./pubdlib.rb publish-book -i 959b583c-59ca-4282-b74d-ee9f32d15458 -p dlts/adl,ifa -e config.local.json

  where [options] are:

BANNER

opts = Optimist.options do
  version 'pubdlib 0.0.2'
  banner banner
  opt :environment, 'Configuration file to use.', type: String
  flags.each do |key, option|
    opt(option[:flag], option[:label], type: option[:type])
  end
end

if opts[:environment].nil?
  Optimist.die :environment, 'Missing configuration file.'
else
  $configuration = JSON.parse(read_resource(opts[:environment])).freeze
end

cmd = ARGV.shift

Optimist.die "Unknown subcommand #{cmd.inspect}." unless subcommands.include? cmd

commands[cmd].flags.select { |flag| flag.required == true }.each do |option|
 abort("ERROR: Flag #{option.flag.red} is required.") if opts[option.flag].nil?
end

task = commands[cmd].new

task.action opts
