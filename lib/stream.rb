# frozen_string_literal: true

require 'json'
require 'nokogiri'
require 'English'
require 'digest'

# @TODO Needs documentation.
class Stream
  @se = nil
  def initialize(se)
    # Structure of DLTS digital objects while in the "Work In Progress" stage.
    # https://github.com/nyudlts/wip-documentation
    # request the Source Entity
    @se = se
  end

  def collections
    collections = []
    @se.hash.isPartOf.each do |item|
      collections.push(
        title: item.name[0, 255],
        name: item.name,
        identifier: item.uuid,
        type: item.type,
        language: 'und',
        code: item.code,
        partner: {
          title: item.provider.name[0, 255],
          name: item.provider.name,
          type: item.provider.type,
          language: 'und',
          identifier: item.provider.uuid,
          code: item.provider.code
        }
      )
    end
    collections
  end

  def partners
    provider = @se.hash.isPartOf[0].provider
    [
      title: provider.name[0, 255],
      name: provider.name,
      type: provider.type,
      language: 'und',
      identifier: provider.uuid,
      code: provider.code
    ]
  end

  def json
    hash.to_json
  end

  def hash
    # @TODO: 3 phases strategy, at the moment we are in step 1
    # as we progress, this script will be updated
    # Currently .vtt and .txt files will be in each WIP aux/ sub directory
    # <digitizationId>.<quality: draft|edited|precision>.<languageCode: ISO 639-1>.<ext: vtt|txt>
    # See for details: https://jira.nyu.edu/jira/browse/DLTSVIDEO-127?focusedCommentId=210439&page=com.atlassian.jira.plugin.system.issuetabpanels%3Acomment-tabpanel#comment-210439
    # representation of the resource
    {
      jobId: "#{@se.hash.isPartOf[0].provider.code}/#{@se.hash.isPartOf[0].code}/#{@se.identifier}",
      identifier: @se.identifier,
      label: @se.identifier,
      entity_language: 'und',
      type: @se.type,
      thumbnails: media_thumbnails,
      manifests: media_manifest,
      handle: @se.handle,
      collection: collections[0],
      partner: partners[0],
      captions: media_captions,
      transcripts: media_transcripts,
      rights: media_rights
    }
  end

  def read_resource(filepath)
    raise "File does not exist #{filepath}" unless File.exist?(filepath)

    File.read(filepath).strip
  end

  # directory containing ephemeral files
  def job_aux_directory
    directory_path = "#{@se.hash.directory_path}/aux"

    raise "Directory containing ephemeral files does not exist #{directory_path}" unless Dir.exist?(directory_path)

    directory_path
  end

  # directory containing non-ephemeral files
  def job_data_directory
    directory_path = "#{@se.hash.directory_path}/data"

    raise "Directory containing non files does not exist #{directory_path}" unless Dir.exist?(directory_path)

    directory_path
  end

  # The representative thumbnail image for this SE
  def media_thumbnails
    # init thumbnails Array
    thumbnails = []
    # See details of the pattern: https://github.com/nyudlts/wip-documentation/blob/master/ie/ie.md
    # `_thumbnail.jpg
    # @TODO: At the moment, I only see _thumbnail.jpg. Implement later on.
    # alternate thumbnail images for this SE
    # `_thumbnail_N.jpg
    Dir.glob("#{job_aux_directory}/*_thumbnail.jpg").sort.each do |thumbnail|
      thumbnail_basename = File.basename(thumbnail)
      thumbnails.push(
        id: thumbnail_basename.gsub(/_thumbnail.jpg/, ''),
        # we collect the basename of the filename
        # append fileServer "protocol" to it.
        # All objects where managed by Drupal
        # and the files where saved in a path
        # managed by Drupal. We want to fix
        # this, but not now.
        # uri: "public://#{thumbnail_basename}"
        uri: "fileServer://av/#{@se.hash.isPartOf[0].provider.code}/#{@se.hash.isPartOf[0].code}/#{@se.hash.digi_id}/#{thumbnail_basename}"
      )
    end
    thumbnails
  end

  def media_transcripts
    # init manifets array
    transcripts = []
    # <partner>/<collection>/<digitizationId>.<quality draft|edited|precision>.<languageCode: ISO 639-1>.<ext: txt>
    # See: https://www.constitution.org/lg/languagecode.html
    # See details of the pattern agreement: https://jira.nyu.edu/jira/browse/DLTSVIDEO-127
    Dir.glob("#{job_aux_directory}/*.txt").sort.each do |transcript|
      basename = File.basename(transcript)
      match = /\.(?<quality>draft|edited|precision){1}\.(?<language>[a-z]{2}|zxx{1}|und{1}|mul{1}|cmn{1}|yue{1})\.(?<extension>txt){1}$/.match(basename)
      next if match.nil?

      captures = match.named_captures

      # Problematic code. See:
      # - https://jira.nyu.edu/browse/DLTSVIDEO-159
      # id = basename.gsub(/.#{captures['extension']}/, '')
      #              .gsub(/.#{captures['quality']}/, '')
      #              .gsub(/.#{captures['language']}/, '')

      # 
      # The id is required because the clip can be a part of a playlist and why we do not
      # use @se.identifier.
      #

      # https://jira.nyu.edu/browse/DLTSVIDEO-159
      # explanation:
      # split the string on '.'
      # capture all array elements except the last 3
      # concatenate the remaining elements with a '.' (in case there was a '.' in the prefix that needs to be preserved)
      id = basename.split('.')[0...-3].join('.')

      transcripts.push(
        id: id,
        uri: "fileServer://av/#{@se.hash.isPartOf[0].provider.code}/#{@se.hash.isPartOf[0].code}/#{@se.hash.digi_id}/#{basename}",
        quality: match['quality'],
        language: match['language']
      )
    end
    transcripts
  end

  def media_captions
    # init captions array
    captions = []
    # find captions using pattern:
    # <partner>/<collection>/<digitizationId>.<quality draft|edited|precision>.<languageCode: ISO 639-1>.<ext: vtt>
    # See: https://www.constitution.org/lg/languagecode.html
    # See details of the pattern agreement: https://jira.nyu.edu/jira/browse/DLTSVIDEO-127
    Dir.glob("#{job_aux_directory}/*.vtt").sort.each do |caption|
      basename = File.basename(caption)
      match = /\.(?<quality>draft|edited|precision){1}\.(?<language>[a-z]{2}|zxx{1}|und{1}|mul{1}|cmn{1}|yue{1})\.(?<extension>vtt){1}$/.match(basename)
      next if match.nil?

      captures = match.named_captures

      # Problematic code. See:
      # - https://jira.nyu.edu/browse/DLTSVIDEO-159
      # id = basename.gsub(/.#{captures['extension']}/, '')
      #              .gsub(/.#{captures['quality']}/, '')
      #              .gsub(/.#{captures['language']}/, '')

      # 
      # The id is required because the clip can be a part of a playlist and why we do not
      # use @se.identifier.
      #

      # https://jira.nyu.edu/browse/DLTSVIDEO-159
      # explanation:
      # split the string on '.'
      # capture all array elements except the last 3
      # concatenate the remaining elements with a '.' (in case there was a '.' in the prefix that needs to be preserved)
      id = basename.split('.')[0...-3].join('.')
      
      captions.push(
        id: id,
        # we collect the basename of the filename
        # append fileServer "protocol" to it.
        uri: "fileServer://av/#{@se.hash.isPartOf[0].provider.code}/#{@se.hash.isPartOf[0].code}/#{@se.hash.digi_id}/#{basename}",
        quality: match['quality'],
        language: match['language']
      )
    end
    captions
  end

  def media_manifest
    # init manifets array
    manifests = []
    # find manifest
    files = Dir.glob("#{job_aux_directory}/*.m3u8")
    # if no manifest, raise error.
    raise "No manifests found for #{job_aux_directory}" if files.size.zero?

    files.sort.each do |manifest|
      # read the manifest so that we can
      # tell if the manifest is what we are expecting
      # it to be and check the stream type
      manifest_string = read_resource(manifest)

      # First line should be: #EXTM3U
      # See https://tools.ietf.org/html/draft-pantos-http-live-streaming-20#section-4.3.1.1
      raise "Found invalid m3u8 file #{manifest}" unless manifest_string.lines[0].strip == '#EXTM3U'

      # Using the the second line of our manifest we can
      # extract the Type and ID of the media
      # Can be either: #VIDEO_ID:* || #AUDIO_ID:*
      #
      # I don't see this atributes in the specification
      # Can someone point me to a place where I can read
      # more about this? All of our resources have this?
      # /\#{1}(VIDEO|AUDIO)(_ID){1}:(.+)/
      #
      # @TODO. Use .named_captures to make this more readable. Eg., ?<type>, ?<id>
      manifest_test = manifest_string.lines[1].match(/\#{1}(VIDEO|AUDIO)(_ID){1}:(.+)/)

      raise "No type/id found for #{manifest}" if manifest_test.nil?

      manifests.push(
        id: manifest_test[3],
        type: manifest_test[1].downcase,
        # A/V materials for publication and AMS publication storage
        # follow the pattern <server>://<partner>/<collection>/<resource>
        uri: "streamServer://#{@se.hash.isPartOf[0].provider.code}/#{@se.hash.isPartOf[0].code}/#{File.basename(manifest)}"
      )
    end
    manifests
  end

  # Rights metadata in METSRights form
  # <something>_rightsmd.xml
  # See: https://github.com/nyudlts/wip-documentation/blob/master/ie/ie.md
  def media_rights
    directory_path = "#{@se.hash.directory_path}/data"
    raise "Directory containing METS rights does not exist #{directory_path}." unless Dir.exist?(directory_path)

    # init rights array
    rights = []
    Dir.glob("#{directory_path}/*_rightsmd.xml").sort.each do |document|
      basename = File.basename(document)
      match = /(?<id>.*)_rightsmd.xml/.match(basename)
      next if match.nil?

      begin
        doc = Nokogiri::XML(read_resource(document))
        captures = match.named_captures
        rights.push(
          id: captures['id'],
          basename: basename,
          body: doc.xpath('xmlns:RightsDeclarationMD/xmlns:RightsDeclaration')[0].text.gsub('\n', '').strip
        )
      rescue RuntimeError
        raise $ERROR_INFO
      end
    end
    rights
  end
end
