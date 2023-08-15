# frozen_string_literal: true

require './lib/handle'

# https://jira.nyu.edu/browse/DLTSAUDIO-71
# Make it so that it loads a with a given NoId and then use the resource profile.

# Need documentation.
class RegisterHandle < Command
  @command = 'register-handle'
  @label = 'Register Handle.'
  @description = 'Register URI.'
  @flags = [
    {
      flag: "noid",
      label: 'Resource noid',
      type: String,
      required: true
    }    
  ]

  def action(opts)
    noid = opts.noid
    bind_uri = "https://sites.dlib.nyu.edu/media/api/v0/noid/#{noid}/embed"
    handle = Handle.new
    handle.bind("2333.1/#{noid}", bind_uri)
  end
end
