#!/usr/bin/env ruby

# frozen_string_literal: true

require 'optimist'
require 'ostruct'
require_relative './lib/command'
require_relative './lib/common'

commands = {}
subcommands = []

Dir[File.expand_path('./commands/*.rb', __dir__)].sort.each do |path|
  require path
  base = File.basename(path, '.rb')
  command = Kernel.const_get(base)
  subcommands.push(command.command)
  commands[command.command] = command
end

Dir[File.expand_path('./actions/*.rb', __dir__)].sort.each { |path| require path }

# Application message to display as banner in the help menu.
banner = <<~BANNER

  Usage: ./pubdlib.rb [subcommand] --flag flag

  Examples:

    $ ./pubdlib.rb publish -i fales_mss222_cuid28860 -e config.local.json

  where [options] are:

BANNER

cmd = ARGV.shift

Optimist.die "Unknown subcommand #{cmd.inspect}." unless subcommands.include? cmd

parsed_opts = Optimist.options do
  version 'pubdlib 1.0.1'
  banner banner
  opt :environment, 'Configuration file to use.', type: String
  commands[cmd].flags.each do |option|
    opt(option[:flag], option[:label], type: option[:type])
  end
end

opts_hash = parsed_opts.to_h
opts_hash.dup.each do |key, value|
  next unless key.is_a?(String)

  sym_key = key.to_sym
  opts_hash[sym_key] = value unless opts_hash.key?(sym_key)
end
opts = OpenStruct.new(opts_hash)

if opts.environment.nil?
  Optimist.die :environment, 'Missing configuration file.'
else
  begin
    $configuration = JSON.parse(read_resource(opts.environment)).freeze
  rescue Errno::ENOENT
    Optimist.die :environment, "Configuration file not found: #{opts.environment}"
  rescue JSON::ParserError => e
    Optimist.die :environment, "Invalid JSON in configuration file: #{e.message}"
  end
end

commands[cmd].flags.select { |flag| flag[:required] == true }.each do |option|
 flag_name = option[:flag]
 abort("ERROR: Flag #{flag_name} is required.") if opts.public_send(flag_name).nil?
end

task = commands[cmd].new

task.action opts
