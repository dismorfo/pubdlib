# frozen_string_literal: true

require 'io/console'

def read_resource(filepath)
  raise "File does not exist #{filepath}." unless File.exist?(filepath)

  File.read(filepath).strip
end

def write_resource(filepath, data)
  # Open the file in write mode ('w')
  # This will create a new file if it doesn't exist, or overwrite the existing content
  File.open(filepath, 'w') do |file|
    file.puts data
  end
  # puts "File '#{file_path}' has been written."
end  

def fit_string_to_terminal(string)
  width = IO.console.winsize[1]  # Get the terminal width

  if string.length > width
    string[0, width - 3] + '...'
  else
    string
  end
end

def is_valid_normalized_isbn13(str)
  # Regular Expressions Cookbook, 2nd Edition, has regexp for ISBN-13
  # https://www.safaribooksonline.com/library/view/regular-expressions-cookbook/9781449327453/ch04s13.html

  # Allows an ISBN-13 with no separators (13 total characters)
  normalized_isbn_regex = /^97[89][0-9]{10}$/

  !str.match(normalized_isbn_regex).nil?
end
