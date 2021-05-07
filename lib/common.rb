# frozen_string_literal: true

def read_resource(filepath)
  raise "File does not exist #{filepath}." unless File.exist?(filepath)

  File.read(filepath).strip
end
