module CompareMethods
  def parse_aleph_data(file)
    aleph_xml = Nokogiri::XML(File.read(file))
    aleph_xml.remove_namespaces!
    aleph_records = Hash.new

    # iterate over records, parsing id, issn and title using xpath
    aleph_xml.xpath("//record").each do |record|
      record_hash = Hash.new
      record_hash[:aleph_id] = record.xpath("datafield[@tag='001']/subfield[@code='a']").text
      record_hash[:issn] = record.xpath("datafield[@tag='022']/subfield[@code='a']").text
      record_hash[:title] = record.xpath("datafield[@tag='245']/subfield[@code='a']").text

      aleph_records[record_hash[:issn].to_sym] = record_hash
    end

    aleph_records
  end


  def get_sfx_input_stream
    App.log.info "Getting input stream from #{settings.sfx_url}"
    open('institutional_holding.xml', 'wb') do |file|
      file << open(settings.sfx_url).read
    end
  end



# this method parses the institutional_holding file
# and stores it in memory for a week at a time
  def parse_sfx_data
    App.log.info 'Parsing sfx data'
    input_stream = File.read(get_sfx_input_stream)
    sfx_records = Array.new
    Holdings.parse(input_stream).items.each do |item|
      sfx_records << item.eissn.downcase.to_sym unless item.eissn.nil?
      sfx_records << item.issn.downcase.to_sym unless item.issn.nil?
    end
    App.log.debug "SFX holdings length is #{sfx_records.size}"
    sfx_records.sort
  end

  def get_missing_records(aleph_records, sfx_records)
    not_present = Array.new
    # if aleph records are not present in sfx
    # then keep them separate
    aleph_records.each do |key, value|
      unless sfx_records.binary_index(key.downcase)
        not_present << value
      end
    end
    not_present
  end

  def render_csv(missing_records)
    CSV.generate(:headers => true, :col_sep => ';') do |csv|
      csv << ['ID', 'ISSN', 'Titel']
      missing_records.each do |record|
        csv << record.values
      end
    end
  end

end