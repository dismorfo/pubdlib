# frozen_string_literal: true

def generate_json_image_set(se)
  entity = Photo.new(se.hash)
  f_json = File.open("#{ENV['CONTENT_REPOSITORY_PATH']}/#{se.type_alias}/#{se.identifier}.#{entity.hash.entity_language}.json", 'w')
  f_json.write(entity.json)
  f_json.close
end

def generate_json(se)
  case se.type
  when 'image_set'
    generate_json_image_set(se)
  end
end
