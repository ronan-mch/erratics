require 'sinatra'
require 'sinatra/reloader'
require 'i18n'
require 'i18n/backend/fallbacks'
require 'nokogiri'
require 'csv'
require 'rbtree'

I18n.load_path += Dir[File.join(File.dirname(__FILE__), 'locales', '*.yml').to_s]

before '/:locale/*' do
	I18n.locale = params[:locale]
	request.path_info = '/' + params[:splat][0]
end

get '/compare' do
	erb :compare_index
end

post '/compare' do
    sfx_url = 'http://sfx.kb.dk/sfx_local/cgi/public/get_file.cgi?file=institutional_holding.xml'
    logger.debug "alephFile is #{params[:alephFile]}.class"
    aleph_records = parse_aleph_data(params[:alephFile][:tempfile])
    sfx_records = parse_sfx_data(sfx_url)
    logger.debug "sfx data is #{sfx_records.inspect}"
    @missing_records = get_missing_records(aleph_records, sfx_records)
    session[:missing_records] = @missing_records
	erb :compare_results
end

  # if the user requests a csv
get '/csv' do
  logger.debug render_csv
  send_data render_csv, :filename => 'comparison.csv'
end

def parse_aleph_data(file)
  aleph_xml = Nokogiri::XML(File.read(file))
  aleph_xml.remove_namespaces!
  aleph_records = RBTree.new

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

def parse_sfx_data(sfx_url)
  sfx_xml = Nokogiri::XML(open(sfx_url))
  sfx_records = RBTree.new

  sfx_xml.xpath("//item").each do |item|
    item_hash = Hash.new
    item_hash[:sfx_id] = item.xpath('sfx_id').text
    item_hash[:title] = item.xpath('title').text
    item_hash[:issn] = item.xpath('issn').text
    item_hash[:eissn] = item.xpath('eissn').text

    sfx_records[item_hash[:issn].to_sym] = item_hash
  end
  sfx_records
end

def get_missing_records(aleph_records, sfx_records)
  not_present = Array.new
  # if aleph records are not present in sfx
  # then keep them separate
  aleph_records.each do |key, value|
    unless sfx_records.key? key
      not_present << value
    end
  end

  not_present
end

def render_csv
  CSV.generate(:col_sep => ';') do |csv|
    csv << ['ID', 'ISSN', 'Titel']
    session[:missing_records].each do |record|
      csv << record.values
    end
  end
end