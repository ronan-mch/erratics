require 'logger'
module App
  extend self
  attr_accessor :log

  # init
  self.log = Logger.new('log/log', 'daily')
  self.log.formatter = proc {|severity, datetime, progname, msg|
                        "#{severity} :: #{datetime.strftime('%Y-%m-%d')} :: #{progname} :: #{msg}\n"}
end