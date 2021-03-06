require 'sinatra'
require 'sinatra/reloader'
require 'i18n'
require 'i18n/backend/fallbacks'
require 'nokogiri'
require 'csv'
require 'open-uri'
require 'binary_search/native'
require './lib/sfx_parser'
require './lib/compare_methods'
require './lib/app'
include SFX_Parser
include CompareMethods

I18n.load_path += Dir[File.join(File.dirname(__FILE__), 'locales', '*.yml').to_s]
I18n.default_locale = :da

before do
  cache_control :public, :must_revalidate, :max_age => 60
  I18n.locale = params[:locale]
end

get '/compare' do
	erb :compare_index
end

post '/compare' do
  aleph_records = parse_aleph_data(params[:alephFile][:tempfile])
  @@missing_records = get_missing_records(aleph_records, @@sfx_records)
	erb :compare_results
end

# allow the user to manually request a data update
get '/refresh' do
  update_sfx_data
  redirect to('/compare?refresh=true')
end

# if the user requests a csv
get '/csv' do
  content_type :csv
  render_csv(@@missing_records)
end

def update_sfx_data
  App.log.info 'Updating sfx data'
  @@sfx_records = parse_sfx_data
  @@sfx_updated = Time.now
end

configure do
  set :sfx_url, 'http://sfx.kb.dk/sfx_local/cgi/public/get_file.cgi?file=institutional_holding.xml'
  @@sfx_updated ||= nil
  @@sfx_records ||= nil
end