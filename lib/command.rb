# frozen_string_literal: true

# Need documentation.
class Command
  @label = ''
  @command = ''
  @description = ''
  @flags = ''

  def action; end

  class << self
    attr_accessor :command, :label, :description, :flags
  end
end
