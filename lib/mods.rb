# frozen_string_literal: true

require 'rubygems'
require 'nokogiri'
require 'json'
# require 'faraday'
require 'iso-639'
require 'date'
require 'digest'

# Not documented class
class Mods
  def initialize(configuration)
    abort("The file #{configuration.xml} does not exist.") unless File.exist?(configuration.xml)
    # Hashes are used to lookup book category according to LCC or DDC
    # classification. Only used for ACO books.
    @ddc_hash = nil
    @ddc_ranges_hash = nil
    @lcc_cat_en = nil
    @lcc_cat_ar = nil
    @ieuu = nil
    @identifier = ''
    @need_category = configuration.need_category
    @is_multivol = configuration.is_multivol
    @script = configuration.script
    @xml = Nokogiri::XML.parse(File.open(configuration.xml)).remove_namespaces!
    @identifier = configuration.identifier
    @need_category = configuration.need_category
    @ieuu = configuration.ieuu
  end

  def identifier
    @identifier
  end

  def title
    xpath = '//mods/titleInfo[not(@type="uniform")'
    if @script != 'Latn'
      xpath += " and @script='#{@script}'" unless @script.nil?
    else
      xpath += ' and (not(@script)'
      xpath += " or  @script='#{@script}'" unless @script.nil?
      xpath += ')'
    end
    xpath += ']'
    title = @xml.xpath("#{xpath}/nonSort/text()").to_s || ''
    title += ' ' if !title.nil? && title !~ /\s+$/
    title += @xml.xpath("#{xpath}/title/text()").first.to_s
    title
  end

  def subtitle
    xpath = '//titleInfo['
    if @script != 'Latn'
      xpath += " @script=\"#{@script}\"" unless @script.nil?
    else
      xpath += ' (not(@script)'
      xpath += " or @script=\"#{@script}\"" unless @script.nil?
      xpath += ')'
    end
    xpath += ']/subTitle'
    @xml.xpath("#{xpath}/text()").to_s
  end

  def authors
    authors = []
    xpath = "//mods/name[@type='personal'"
    if @script != 'Latn'
      xpath += " and @script=\"#{@script}\"" unless @script.nil?
    else
      xpath += ' and (not(@script)'
      xpath += " or  @script=\"#{@script}\"" unless @script.nil?
      xpath += ')'
    end
    xpath += ']'
    names = @xml.xpath(xpath)
    names.each do |node|
      name_parts = node.xpath('./namePart[not(@type="date")]/text()').to_s.strip
      date = node.xpath('./namePart[@type="date"]/text()').to_s.strip
      role = node.xpath('./role/roleTerm[@type="text"]/text()').to_s.strip
      author = [name_parts, date, role].reject(&:empty?).join(', ')
      authors << author
    end
    authors
  end

  def notes
    raw_notes = []
    xpath = "//note | //genre[\@authority='lcgft']"
    @nodes = mods_doc.xpath(xpath)
    @nodes.each do |node|
      note = node.xpath('./text()').to_s.strip
      if !note.empty?
        raw_notes << note
      end
    end
    raw_notes
  end

  def physical_description
    @xml.xpath('//physicalDescription/extent/text()')
  end

  def publisher
    xpath = '//originInfo['
    if @script != 'Latn'
      xpath += "@script=\"#{@script}\"" unless @script.nil?
    else
      xpath += " not(@script) or  @script=\"#{@script}\""
    end
    xpath += ']/publisher'
    @xml.xpath("#{xpath}/text()").first
  end

  def call_number(marc_file_mapping, marc_file_path)
    xpath = "//classification[\@authority='lcc']"
    call_number = @xml.xpath("#{xpath}/text()").to_s
    if call_number.empty? && marc_file_mapping != nil
      call_number = call_number_from_marc(marc_file_mapping, marc_file_path)
    end
    call_number
  end

  def call_number_from_marc(marc_file_mapping, marc_file_path)
    f = File.open(marc_file_mapping, 'r')
    call_number = ''
    f.each_line do |line|
      marc_files = line.split(' ')
      if marc_files.include?(@identifier)
        marc_file_full_path = marc_file_path + '/NjP_' + marc_files[0] + '_marcxml.xml'
        if File.exist?(marc_file_full_path)
          marc_xml = Nokogiri::XML.parse(File.open(marc_file_full_path)).remove_namespaces!
          xpath = "//datafield[@tag='852']/subfield[@code="
          call_number = marc_xml.xpath("#{xpath}'h']/text()").to_s + ' ' + marc_xml.xpath("#{xpath}'i']/text()").to_s
        else
          puts 'Marc file is missing.'
        end
      end
    end
    f.close
    call_number
  end

  def description
    xpath = '//abstract'
    @xml.xpath("#{xpath}/text()").to_s
  end

  def language
    if language_code.nil?
      ISO_639.find_by_code('eng').english_name
    else
      ISO_639.find_by_code(language_code.to_s).english_name
    end
  end

  def entity_language
    language = 'en'
    if @script == 'Arab'
      iso_map = JSON.parse(File.read('./include/iso-639-2.json'))
      language = iso_map[language_code.to_s]
    end
    language
  end

  def language_code
    xpath = "//language/languageTerm[@authority='iso639-2b' and @type='code']/text()"
    @xml.xpath(xpath).first
  end

  def number
    @xml.xpath('//physicalDescription/extent/text()').to_s
  end

  def subject
    subjects = []
    xpath = "//subject[@script='#{@script}' "
    xpath += 'or not(@script)' if @script == 'Latn'
    xpath += ']'

    @xml.xpath(xpath).each do |node|
      subj = leaf_vals(node, [])
      subjects << subj.join(' -- ') unless subj.empty? || subj.size == 0 || subj == ''
    end

    xpath = "//genre[\@authority='lcgft'] "
    subjects << @xml.xpath("#{xpath}/text()").to_s

    subjects.uniq.reject(&:empty?)
  end

  # Get a list scripts in this mod file.
  def scripts
    @xml.xpath('//@script').map(&:to_s).uniq
  end

  def leaf_vals(subj_element, values)
    children = subj_element.elements
    if !children.empty?
      children.each do |child|
        if child.name != 'geographicCode' && child.name != 'cartographics'
          leaf_vals(child, values)
        end
      end
    else
      val = subj_element.text
      values << val unless val == '' || val.nil?
    end
    values
  end

  def publication_location
    xpath = '//originInfo['
    if @script != 'Latn'
      xpath += " @script=\"#{@script}\"" unless @script.nil?
    else
      xpath += ' (not(@script)'
      xpath += " or  @script=\"#{@script}\"" unless @script.nil?
      xpath += ')'
    end
    xpath += "]/place/placeTerm[\@type='text']"
    @xml.xpath("#{xpath}/text()").to_s
  end

  def pub_date_string
    xpath = '//originInfo[ (not(@script) or @script="Latn" )'
    xpath += "]/dateIssued[not(@encoding='marc')]"
    date = @xml.xpath("#{xpath}/text()")
    return '' if date.nil?

    date_text = date.to_s.gsub('u', '0')
    date_text = date_text.gsub('&lt;', '')
    date_text = date_text.gsub('&gt;', '')
    date_text
  end

  def pub_date
    return '' if pub_date_string == ''

    date = pub_date_string
    return DateTime.parse("#{date.to_s[0, 4]}-01-01").strftime("%C%y-%m-%dT%H:%M:%S") if (Date.new(date.to_s[0, 4].to_i)).gregorian?

    xpath = "//originInfo[(not(@script) or  @script=\"Latn\")"
    xpath += "]/dateIssued[(@encoding='marc')]"
    date_marc = @xml.xpath("#{xpath}/text()")

    if !date_marc.nil?
      date_marc_fin = date_marc.to_s[0, 4].gsub('u', '0')
     return DateTime.parse("#{date_marc_fin}-01-01").strftime("%C%y-%m-%dT%H:%M:%S") if (Date.new(date_marc_fin.to_i)).gregorian?
    end

    xpath = "//originInfo[(not(@script) or  @script=\"Latn\")"

    xpath += "]/dateIssued[point='start']"

    date_marc_start = @xml.xpath("#{xpath}/text()")

    if !date_marc_start.nil?
      date_marc_fin = date_marc.to_s[0, 4].gsub('u', '0')
      return DateTime.parse("#{date_marc_fin}-01-01").strftimer("%C%y-%m-%dT%H:%M:%S") if (Date.new(date_marc_fin.to_i)).gregorian?
    end

    date_ajust_first = date.sub(/.*?\[/, '')
    date_ajust = date_ajust_first.gsub(/[^0-9]/i, '')
    date_final = date_ajust.ljust(4, '0')

    return DateTime.parse("#{date_final}-01-01").strftime("%C%y-%m-%dT%H:%M:%S") if (Date.new(date_ajust.to_i)).gregorian?

    ''
  end

  def topic(marc_file_mapping, marc_file_path)
    topic = ''
    @need_category = true # For now. Why do we need to test?
    if @need_category
      if @ddc_hash.nil?
        @ddc_hash = eval(File.read('include/category_hashes/ddc_hash'))
      end

      if @ddc_ranges_hash.nil?
        @ddc_ranges_hash = eval(File.read('include/category_hashes/ddc_range'))
      end

      if @lcc_cat_en.nil?
        @lcc_cat_en = eval(File.read('include/category_hashes/lcc_cat_en'))
      end

      if @lcc_cat_ar.nil?
        @lcc_cat_ar = eval(File.read('include/category_hashes/lcc_cat_ar'))
      end

      xpath = '//classification[@authority="lcc"]'

      call_number = @xml.xpath("#{xpath}/text()").to_s

      if (call_number.nil? || call_number.empty?) && marc_file_mapping != nil
        call_number = call_number_from_marc(marc_file_mapping, marc_file_path)
      end

      if !call_number.nil? && !call_number.empty?
        topic = topic_lcc_lookup(call_number[0])
      else
        xpath = "//classification[\@authority='ddc']"
        call_number = mods_doc.xpath("#{xpath}/text()").to_s
        if !call_number.nil? && !call_number.empty?
          topic = topic_from_ddc(call_number)
        end
        if topic.empty? || topic.nil?
          class_value = call_number.split('.')[0]
          topic = topic_from_ddc(class_value)
        end
      end
    end
    topic
  end

  def topic_from_ddc(call_number)
    topic = ''
    first_letter = @ddc_hash[call_number]
    if !first_letter.nil? && !first_letter.empty?
      return topic_lcc_lookup(first_letter)
    else
      @ddc_ranges_hash.each do |fl, ddc_ranges|
        ddc_ranges.each do |ddc_range|
          if ddc_range.include?(call_number)
            return topic_lcc_lookup(fl)
          end
        end
      end
    end

    topic
  end

  def topic_lcc_lookup(first_letter)
    topic = []
    if @script == 'Latn'
      topic.push(@lcc_cat_en[first_letter])
    else
      topic.push(@lcc_cat_ar[first_letter])
    end
    topic
  end

  def multivolume(ie)
    volume = []
    if @script == 'Latn' && ie.is_multivol
      volume = [
        {
          identifier: ie.ieuu,
          volume_number: ie.order,
          volume_number_str: ie.orderlabel,
          collection: ie.collections,
          isPartOf: [
            {
              'title': "#{ie.ieuu} - #{ie.identifier}",
              'type': 'dlts_multivol',
              'language': 'und',
              'identifier': ie.ieuu,
              'ri': nil
            }
          ]
        }
      ]
    end
    volume
  end

  def series(ie)
    if @script == 'Latn'
      xpath = "//relatedItem[@type='series']/titleInfo[@script='#{@script}' "
      xpath += ' or not(@script) ' if @script == 'Latn'
      xpath += ']/title/text()'
      titles = @xml.xpath(xpath)
      serieses_str = []
      titles.each do |title|
        title.to_s.gsub!(/no\./, ';no.')
        title.to_s.gsub!(/n\./, ';n.')
        title.to_s.gsub!(/v\./, ';v.')
        serieses_str << title.to_s.split(';')
      end
      serieses = []
      serieses_str.each do |series|
        series_id = Digest::MD5.hexdigest(series[0])
        if !series[1].nil?
          volume_number = /\d+/.match(series[1])
        end
        data = {
          :identifier => "series_#{book_id}_#{series_id}",
          :type => 'dlts_series_book',
          :title => series[0],
          :volume_number => "#{volume_number}",
          :volume_number_str =>"#{series[1]}",
          :collection => ie.collection,
          :isPartOf => [
            {
              :title => series[0],
              :type => "dlts_series",
              :language => "und",
              :identifier => "series_#{series_id}",
              :ri => nil
            }
          ]
        }
        serieses << data
      end
      serieses
    else
      ''
    end
  end
end
