# frozen_string_literal: true

# Need documentation.
class UpdateHandle < Command
  @command = 'update-handle'
  @label = 'Update handle.'
  @description = 'Update handle.'
  @flags = [
    {
      flag: 'identifier',
      label: 'Identifier.',
      type: String
    },
    {
      flag: 'from',
      label: 'Handle Id',
      type: String
    },
    {
      flag: 'to',
      label: 'Redirect Url',
      type: String
    },
  ]

  def action(opts)
    require 'nice_http'
    require 'json'
    require './lib/se'
    require './lib/handle'

    entity = search_se_by_id(opts.identifier)

    abort unless entity
    if entity
      puts "Found SE with identifier #{opts.identifier} and type #{entity['resource']['do_type']}."
      fids = entity['resource']['fids']
      id = fids['handle'] if fids && fids['handle']
      if opts.to && id
        handle = Handle.new
        handle.bind(id.to_s, opts.to)
        puts "From #{$configuration['HANDLE_REDIRECTS']}/#{id}  to #{opts.to}"
      end

    else
      puts "Unable to find SE with identifier #{opts.identifier}."
    end

  end

  private

  def search_se_by_id(identifier)
    http = NiceHttp.new($configuration['SE_ENDPOINT'])

    resp = http.post(
      {
        path: '/api/v0/import/user/login.json',
        headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
        data: {
          'username': $configuration['SE_USER'],
          'password': $configuration['SE_PASS']
        }
      }
    )
    raise 'Unable to authenticate to search service.' unless resp.code == 200

    resp = http.get({ path: "/api/v1/repository/search?digi_id=#{identifier}" })
    raise "Unable to find resource #{identifier} in search service." unless resp.code == 200

    JSON.parse(resp.data)
  end

end
