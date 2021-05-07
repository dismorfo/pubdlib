def link_handle(identifier)
  se = Se.new(identifier)
  profile = se.hash.profile

  case se.type
    when 'image_set'
      photo = Photo.new(se.hash)
      count = photo.sequence_count.to_i
      # "WITH" OR "WITHOUT" thumbnail
      # @link https://jira.nyu.edu/jira/browse/DLTSIMAGES-325?focusedCommentId=1500278&page=com.atlassian.jira.plugin.system.issuetabpanels%3Acomment-tabpanel#comment-1500278
      # - If SE has one sequence, then it will be publish with thumbnails
      if count == 1
        bind_uri = "#{profile.mainEntityOfPage}/#{profile.types[se.type]}/#{identifier}/1"
        # - If SE has more than one sequence it will be publish without thumbnails
      else
        bind_uri = "#{profile.mainEntityOfPage}/#{profile.types[se.type]}/#{identifier}"
      end
      handle = Handle.new
      handle.bind(se.handle, bind_uri)
  end
end
