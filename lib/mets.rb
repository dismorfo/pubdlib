require 'rubygems'
require 'nokogiri'
require 'json'
require 'iso-639'
require 'date'
require 'digest'
require 'saxerator'

class Mets

  def initialize(se, script)
    @se = se
    @identifier = se.identifier
    @script = script
  end

  def doc
    Nokogiri::XML.parse(doc_raw).remove_namespaces!
  end

  def mod
    Nokogiri::XML.parse(mod_raw).remove_namespaces!
  end

  def doc_raw
    File.open(met_file_path).read
  end

  def mod_raw
    File.open(mod_file_path).read
  end

  def met_file_path
    mets_file = "#{content_root}/data/#{@identifier}_mets.xml"
    abort("The file #{mets_file} for the resource #{@identifier} doesn't exist.") unless File.exist?(mets_file)
    mets_file
  end

  def mod_file_path
    mods_file_name = doc.xpath('//mdRef[@MDTYPE="MODS"]/@href').to_s
    mods_file_path = "#{content_root}/data/#{mods_file_name}"
    abort("The file #{mods_file_path} for the resource #{@identifier} doesn't exist.") unless File.exist?(mods_file_path)
    mods_file_path
  end

  def rights
    rights_file_name = doc.xpath('//mdRef[@MDTYPE="METSRIGHTS"]/@href').to_s
    rights_file = "#{content_root}/data/#{rights_file_name}"
    abort("The file #{rights_file} for the serial #{@identifier} doesn't exist.") unless File.exist?(rights_file)

    rights_doc_xml = Nokogiri::XML.parse(File.open(rights_file)).remove_namespaces!
    rights_doc_xml.xpath("//RightsDeclaration/text()").to_s.strip
  end

  def struct_settings
    # 1. Try to find the attribute
    node = doc.at_xpath('//xmlns:structMap/@TYPE', 'xmlns' => 'http://www.loc.gov/METS/')
  
    # 2. If node is nil, try without namespace as a fallback (some parsers prefer this)
    node ||= doc.at_xpath('//structMap/@TYPE')

    # 3. Return an empty hash instead of crashing if nothing is found
    return {} if node.nil?

    # 4. Extract value and parse
    node.value.split(' ').map { |s| s.split(':', 2) }.to_h
  rescue => e
    puts "Warning: Error parsing structMap TYPE: #{e.message}"
    {}
  end

  # 0|Left to right
  # 1|Right to left
  def read_order
    self.read_order_string =~ /right(2|_to_)left/i ? 1 : 0
  end

  def read_order_string
    self.struct_settings['READ_ORDER']
  end

  # 0|Left to right
  # 1|Right to left
  def scan_order
    self.scan_order_string =~ /right(2|_to_)left/i ? 1 : 0
  end

  def scan_order_string
    self.struct_settings['SCAN_ORDER']
  end

  def page_count
    doc.xpath('//structMap/div/div[@TYPE="INTELLECTUAL_ENTITY"]/div').size
  end

  def sequence_count
    doc.xpath('//structMap/div/div[@TYPE="INTELLECTUAL_ENTITY"]/div').size
  end

  # Map: binding_orientation
  # 0|Vertical
  # 1|Horizontal
  def binding_orientation
    self.binding_orientation_string =~ /horizontal/i ? 1 : 0
  end

  def binding_orientation_string
    self.struct_settings['BINDING_ORIENTATION']
  end

  def title
    xpath = "//mods/titleInfo[not(@type=\"uniform\") "
    if @script != "Latn"
      xpath += " and @script=\"#{@script}\"" unless @script.nil?
    else
      xpath += " and (not(@script)"
      xpath += " or  @script=\"#{@script}\"" unless @script.nil?
      xpath += ")"
    end
    xpath += "]"
    title  = mod.xpath("#{xpath}/nonSort/text()").to_s || ""
    title  += " " if !title.nil? && title !~ /\s+$/
    title  += mod.xpath("#{xpath}/title/text()").first.to_s
    title.strip
  end

  def subtitle
    xpath = "//titleInfo["
    if @script != "Latn"
      xpath += " @script=\"#{@script}\"" unless @script.nil?
    else
      xpath += " (not(@script)"
      xpath += " or  @script=\"#{@script}\"" unless @script.nil?
      xpath += ")"
    end
    xpath    += "]/subTitle"
    subtitle  = mod.xpath("#{xpath}/text()").to_s
    subtitle.empty? ? [] : [subtitle]
  end

  def authors
    authors = []

    # Start with the base tag. Notice we don't open the '[' bracket here anymore.
    xpath = '//mods/name'

    # Group the type condition and the script conditions together
    conditions = ["(@type='personal' or @type='corporate')"]

    if @script != 'Latn'
      conditions << "@script=\"#{@script}\"" unless @script.nil?
    else
      # Wraps the script conditions in their own parenthesis group
      script_cond = 'not(@script)'
      script_cond += " or @script=\"#{@script}\"" unless @script.nil?
      conditions << "(#{script_cond})"
    end

    xpath += "[#{conditions.join(' and ')}]"

    mod.xpath(xpath).each do |node|
      name_parts = node.xpath('./namePart[not(@type="date")]/text()').to_s.strip
      date       = node.xpath('./namePart[@type="date"]/text()').to_s.strip
      role       = node.xpath('./role/roleTerm[@type="text"]/text()').to_s.strip

      author     = [name_parts, date, role].reject(&:empty?).join(', ')
      authors << author unless author.empty?
    end
    authors
  end

  def notes
    notes = []
    mod.xpath("//note | //genre[@authority='lcgft']").each do |node|
      note = node.xpath("./text()").to_s.strip
      notes << note unless note.empty?
    end
    notes
  end

  def physical_description
    result = mod.xpath("//physicalDescription/extent/text()")
    result.empty? ? [] : [result.to_s.strip]
  end

  def publisher
    xpath = "//originInfo["
    if @script != 'Latn'
      xpath += "@script=\"#{@script}\"" unless @script.nil?
    else
      xpath += " not(@script) or  @script=\"#{@script}\""
    end
    xpath += "]/publisher"
    mod.xpath("#{xpath}/text()").first
  end

  def call_number(marc_file_mapping = nil, marc_file_path = nil)
    call_number = mod.xpath("//classification[@authority='lcc']/text()").to_s
    if call_number.empty? && !marc_file_mapping.nil?
      call_number = call_number_from_marc(marc_file_mapping, marc_file_path)
    end
    call_number = call_number.to_s.strip
    call_number.empty? ? [] : [call_number]
  end

  def call_number_from_marc(marc_file_mapping, marc_file_path)
    call_number = ""
    File.foreach(marc_file_mapping) do |line|
      marc_files = line.split(" ")
      next unless marc_files.include?(@identifier)

      marc_file_full_path = "#{marc_file_path}/NjP_#{marc_files[0]}_marcxml.xml"
      next unless File.exist?(marc_file_full_path)

      marc_xml    = Nokogiri::XML.parse(File.open(marc_file_full_path)).remove_namespaces!
      xpath       = "//datafield[@tag='852']/subfield[@code="
      call_number = marc_xml.xpath("#{xpath}'h']/text()").to_s + " " +
                    marc_xml.xpath("#{xpath}'i']/text()").to_s
    end
    call_number
  end

  def description
    mod.xpath('//abstract/text()').to_s
  end

  def language
    code = language_code
    ISO_639.find_by_code(code.nil? ? 'eng' : code.to_s).english_name
  end

  def language_code
    mod.xpath("//language/languageTerm[@authority='iso639-2b' and @type='code']/text()").first
  end

  def number
    value = mod.xpath("//physicalDescription/extent/text()").to_s.strip
    value.empty? ? [] : [value]
  end

  def subject
    subjects = []
    xpath = "//subject[@script='#{@script}' "
    xpath += "or not(@script)" if @script == "Latn"
    xpath += "]"

    mod.xpath(xpath).each do |node|
      subject = leaf_vals(node, [])
      subjects << subject.join(' -- ') unless subject.empty?
    end

    subjects << mod.xpath("#{xpath}/text()").to_s.strip
    subjects.uniq.reject(&:empty?)
  end

  def leaf_vals(subj_element, values)
    children = subj_element.elements
    if children.empty?
      val = subj_element.text
      values << val unless val.nil? || val.empty?
    else
      children.each do |child|
        leaf_vals(child, values) unless %w[geographicCode cartographics].include?(child.name)
      end
    end
    values
  end

  def publication_location
    xpath = "//originInfo["
    if @script != "Latn"
      xpath += " @script=\"#{@script}\"" unless @script.nil?
    else
      xpath += " (not(@script)"
      xpath += " or  @script=\"#{@script}\"" unless @script.nil?
      xpath += ")"
    end
    xpath += "]/place/placeTerm[@type='text']"
    location = mod.xpath("#{xpath}/text()").to_s.strip
    location.empty? ? [] : [location]
  end

  def publication_date_string
    xpath = "//originInfo[ (not(@script) or @script=\"Latn\" )"
    xpath += "]/dateIssued[not(@encoding='marc')]"
    date = mod.xpath("#{xpath}/text()").to_s.strip
    date.empty? ? [] : [date]
  end

  def publication_date(date)
    date = date.first if date.is_a?(Array)
    return [] if date.nil? || date == ""

    if Date.new(date.to_s[0, 4].to_i).gregorian?
      return [DateTime.parse("#{date.to_s[0, 4]}-01-01").strftime("%C%y-%m-%dT%H:%M:%S")]
    end

    xpath = "//originInfo[(not(@script) or  @script=\"Latn\")]/dateIssued[(@encoding='marc')]"
    date_marc = mod.xpath("#{xpath}/text()")

    unless date_marc.nil?
      date_marc_fin = date_marc.to_s[0, 4].gsub('u', '0')
      if Date.new(date_marc_fin.to_i).gregorian?
        return [DateTime.parse("#{date_marc_fin}-01-01").strftime("%C%y-%m-%dT%H:%M:%S")]
      end
    end

    xpath = "//originInfo[(not(@script) or  @script=\"Latn\")]/dateIssued[point='start']"
    date_marc_start = mod.xpath("#{xpath}/text()")

    unless date_marc_start.nil?
      date_marc_fin = date_marc_start.to_s[0, 4].gsub('u', '0')
      if Date.new(date_marc_fin.to_i).gregorian?
        return [DateTime.parse("#{date_marc_fin}-01-01").strftime("%C%y-%m-%dT%H:%M:%S")]
      end
    end

    date_adjust = date.sub(/.*?\[/, '').gsub(/[^0-9]/i, '').ljust(4, '0')
    if Date.new(date_adjust.to_i).gregorian?
      return [DateTime.parse("#{date_adjust}-01-01").strftime("%C%y-%m-%dT%H:%M:%S")]
    end

    []
  end

  def topic(need_category, marc_file_mapping, marc_file_path)
    return "" unless need_category

    @ddc_hash        ||= eval(File.read("category_hashes/ddc_hash"))
    @ddc_ranges_hash ||= eval(File.read("category_hashes/ddc_range"))
    @lcc_cat_en      ||= eval(File.read("category_hashes/lcc_cat_en"))
    @lcc_cat_ar      ||= eval(File.read("category_hashes/lcc_cat_ar"))

    call_number = mod.xpath("//classification[@authority='lcc']/text()").to_s
    if (call_number.nil? || call_number.empty?) && !marc_file_mapping.nil?
      call_number = call_number_from_marc(marc_file_mapping, marc_file_path)
    end

    if !call_number.nil? && !call_number.empty?
      return topic_lcc_lookup(call_number[0])
    end

    call_number = mod.xpath("//classification[@authority='ddc']/text()").to_s
    unless call_number.nil? || call_number.empty?
      topic = topic_from_ddc(call_number)
      return topic unless topic.empty? || topic.nil?
      return topic_from_ddc(call_number.split('.')[0])
    end

    ""
  end

  def topic_from_ddc(call_number)
    first_letter = @ddc_hash[call_number]
    if !first_letter.nil? && !first_letter.empty?
      return topic_lcc_lookup(first_letter)
    end

    @ddc_ranges_hash.each do |letter, ddc_ranges|
      ddc_ranges.each do |ddc_range|
        return topic_lcc_lookup(letter) if ddc_range.include?(call_number)
      end
    end

    ""
  end

  def topic_lcc_lookup(first_letter)
    topic = @script == 'Latn' ? @lcc_cat_en[first_letter] : @lcc_cat_ar[first_letter]
    [topic]
  end

  def multivolume(id, volume, volume_str, collection_id, partner_id, multi_vol)
    return [] unless @script == "Latn" && multi_vol

    [
      {
        identifier: id.to_s,
        volume_number: volume.to_s,
        volume_number_str: volume_str.to_s,
        collection: collections,
        isPartOf: [
          {
            title: "Multi-Volume #{id}",
            type: "dlts_multivol",
            language: "und",
            identifier: id.to_s,
            ri: nil
          }
        ]
      }
    ]
  end

  def generate_map_page(parser)
    map   = parser.for_tag(:div).with_attributes({ TYPE: "INTELLECTUAL_ENTITY" }).first
    page  = map['div']
    label = page.attributes["ID"].gsub('s-', '')
    order = page.attributes["ORDER"].to_i

    [{
      isPartOf:       @identifier,
      sequence:       [order],
      realPageNumber: order,
      cm: {
        uri:       "fileserver://maps/#{@identifier}/#{label}_d.jp2",
        width:     "",
        height:    "",
        timestamp: Time.now.to_i.to_s
      }
    }]
  end

  def sequences
    parser = Saxerator.parser(File.new(self.met_file_path))

    single_pages = []

    map = parser.for_tag(:div).with_attributes({:TYPE => "INTELLECTUAL_ENTITY"}).first

    if map['div'].length > 1
      map['div'].each.with_index do |page, index|
        label = page.attributes["ID"].gsub('s-', '')
        order = page.attributes["ORDER"].to_i      
        image_id = "#{@se.type_alias}/#{@identifier}/#{label}_d.jp2"
        sequence_metadata = @se.image_metadata(image_id)
        page = {
          :isPartOf => @identifier, 
          :sequence => [order], 
          :realPageNumber => order,
          :cm => {
            :uri => "fileserver://#{image_id}", 
            width: sequence_metadata.width,
            height: sequence_metadata.height
          }
        }
        single_pages << page
      end
    else
      page = map['div']
      label = page.attributes["ID"].gsub('s-', '')
      order = page.attributes["ORDER"].to_i
      image_id = "#{@se.type_alias}/#{@identifier}/#{label}_d.jp2"
      sequence_metadata = @se.image_metadata(image_id)
      single_pages << {
        :isPartOf => @identifier,
        :sequence => [ order ],
        :realPageNumber => order,
        :cm => {
          :uri => "fileserver://#{@se.type_alias}/#{@identifier}/#{label}_d.jp2",
	        :width => sequence_metadata.width,
  	      :height => sequence_metadata.height,
        }
      }
    end
    single_pages
  end

  def series(collection_id, partner_id)
    return [] unless @script == 'Latn'

    xpath = "//relatedItem[@type='series']/titleInfo[@script='#{@script}' "
    xpath += ' or not(@script) ' if @script == 'Latn'
    xpath += ']/title/text()'

    mod.xpath(xpath).flat_map do |title_node|
      title_str = title_node.to_s
                            .gsub(/no\./, ';no.')
                            .gsub(/n\./, ';n.')
                            .gsub(/v\./, ';v.')
      parts = title_str.split(';')
      series_id = Digest::MD5.hexdigest(parts[0])
      vol_num = parts[1] ? /\d+/.match(parts[1]) : nil

      {
        identifier: "series_#{@identifier}_#{series_id}",
        type: 'dlts_series_book',
        title: parts[0],
        volume_number: vol_num.to_s,
        volume_number_str: parts[1].to_s,
        collection: [collection(collection_id, partner_id)[0]],
        isPartOf: [
          {
            title: parts[0],
            type: 'dlts_series',
            language: 'und',
            identifier: "series_#{series_id}",
            ri: nil
          }
        ]
      }
    end
  end

  def collections
    @se.collections
  end

  def partners
    @se.partners
  end

  def representative_image
    rep_image_div = doc.xpath('//structMap/div/div[@TYPE="INTELLECTUAL_ENTITY"]/div').first
    label = rep_image_div.xpath('@ID').to_s.gsub('s-', '')

    image_id = "#{@se.type_alias}/#{@identifier}/#{label}_d.jp2"
    sequence_metadata = @se.image_metadata(image_id)

    {
      isPartOf: @identifier,
      sequence: [1],
      realPageNumber: 1,
      cm: {
        uri: "fileserver://#{@se.type_alias}/#{@identifier}/#{label}_d.jp2",
        width: sequence_metadata['width'],
        height: sequence_metadata['height'],
        timestamp: Time.now.to_i.to_s
      }
    }
  end

  private

  def content_root
    "#{$configuration['RSBE_CONTENT']}/#{@se.partner_code}/#{@se.collection_code}/wip/se/#{@identifier}"
  end
end
