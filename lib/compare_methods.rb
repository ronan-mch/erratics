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
    puts 'getting input stream'
    open('institutional_holding.xml', 'wb') do |file|
      file << open(settings.sfx_url).read
    end
  end



# this method parses the institutional_holding file
# and stores it in memory for a week at a time
  def parse_sfx_data
    puts 'parsing sfx_data'
    t1 = Time.now
    input_stream = File.read(get_sfx_input_stream)
    t2 = Time.now
    puts "getting input stream took #{time_diff_milli(t1,t2)}"
    sfx_records = Array.new

    t1 = Time.now
    Holdings.parse(input_stream).items.each do |item|
      sfx_records << item.eissn.to_sym unless item.eissn.nil?
      sfx_records << item.issn.to_sym unless item.issn.nil?
    end
    t2 = Time.now
    puts "parsing sfx data took #{time_diff_milli(t1,t2)}"
    sfx_records.sort
  end

  def get_missing_records(aleph_records)
    t1 = Time.now
    not_present = Array.new
    # if aleph records are not present in sfx
    # then keep them separate
    puts "sfx_records length is #{@@sfx_records.size}"
    aleph_records.each do |key, value|
      unless @@sfx_records.binary_index(key)
        not_present << value
      end
    end
    t2 = Time.now
    puts "getting missing records took #{time_diff_milli(t1,t2)}"
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


  def time_diff_milli(start, finish)
    (finish - start) * 1000.0
  end



end