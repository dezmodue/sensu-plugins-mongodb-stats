#!/usr/bin/env ruby
require 'rubygems' if RUBY_VERSION < '1.9.0'
require 'mongo'
require 'simple-graphite'
require 'sensu-plugin/metric/cli'

class MongodbMetrics < Sensu::Plugin::Metric::CLI::Graphite
  THIS_HOST = `hostname -s`.chomp

  option :host,
         :short => '-h HOST',
         :description => "MongoDB host to connect to",
         :long => "--host HOST",
         :default => THIS_HOST

  option :port,
         :short => '-p PORT',
         :description => "MongoDB port to connect to",
         :long => "--port PORT",
         :default => 27017

  option :list_exclude,
         :description => "Comma delimited list of metrics to exclude",
         :long => "--list_exclude EXCLUDELIST",
         :default => ''

  option :list_include,
         :description => "Comma delimited list of metrics to include",
         :long => "--list_include INCLUDELIST",
         :default => ''

  option :prefix,
         :description => "Prefix to add to the metric",
         :long => "--prefix PREFIX",
         :default => nil

  option :filter_exclude,
         :description => "Regular expression for excluding metrics",
         :long => "--filter-exclude EXCLUDEREGEX",
         :default => ''

  option :filter_include,
         :description => "Regular expression for including metrics",
         :long => "--filter-include INCLUDEREGEX",
         :default => ''

  option :help,
         :long => "--help",
         :default => false

  option :debug,
         :long => "--debug",
         :default => false

  Mongo::Logger.logger.level = ::Logger::FATAL


  # monkey patch the graphite class so we can set the timestamp correctly
  class Graphite

    def send_metrics(metrics_hash,timestamp=nil)
      current_time = timestamp.nil? ? time_now : timestamp
      puts "Current time: #{current_time}"
      push_to_graphite do |graphite|
        graphite.puts((metrics_hash.map { |k,v| [k, v, current_time].join(' ') + "\n" }).join(''))
      end
      current_time
    end

  end

  def hash_to_dot_notation(h,f=[],g={})
    return g.update({ f.join('.')=>h }) unless h.is_a? Hash
    h.each do |k, r|
      k='dot' if k == '.'
      hash_to_dot_notation(r, f+[k], g)
    end
    g
  end

  def get_member_type(status)
    # Get the member type
    if (status['repl']['ismaster'] rescue false)
      'primary'
    elsif (status['repl']['secondary'] rescue false)
      'secondary'
    elsif (status['repl']['arbiters'].include?(status['host']) rescue false)
      'arbiter'
    else
      'other'
    end
  end

  def mongoconnect(host,port)
    Mongo::Client.new([ "#{host}:#{port.to_s}" ])
  end

  def run
    if config[:help]
      puts "Collect metrics from MongoDB server status. Use include and exclude list/regex to limit the metrics returned"
      puts "You can use both lists and filters to restrict the metrics to collect"
      warning "The processing order is: list_include filter_include filter_exclude list_exclude"
    else
      remove = %(localTime host version process extra_info.note repl.setName repl.secondary repl.hosts repl.arbiters repl.primary repl.me mem.bits repl.ismaster)
      prefix = config[:prefix]

      excluderegex = config[:filter_exclude].split(',')
      includeregex = config[:filter_include].split(',')
      excludelist = config[:list_exclude].split(',')
      includelist = config[:list_include].split(',')

      client = mongoconnect(config[:host],config[:port])

      complete_status = client.command({'serverStatus' => 1})
      status = complete_status.documents.first
      # Get the real timestamp from within serverStatus # if nil it will use default g.time_now
      timestamp = status['localTime'].to_i rescue nil

      result = hash_to_dot_notation(status)

      # Set replicaset name and short hostname
      replicaset = status['repl']['setName'] rescue 'standalone'
      hostname = status['host'].split('.')[0]

      # Build the metrics hash
      metrics = Hash.new

      unless prefix.nil? || prefix.end_with?('.')
        prefix = "#{prefix}."
      end

      # Exclude some values by default
      result.delete_if{|k,| remove.include? k }

      # Apply filters in order
      if includelist.count > 0
        result.delete_if{ |k,| ! includelist.include? k }
      end

      if includeregex.count > 0
        spare = []
        includeregex.each do |m|
          result.each do |k,|
            spare << k if k.match(m.gsub("\\\\"){"\\"})
          end
        end
        result.delete_if{|k,| ! spare.include? k }
      end

      if excluderegex.count > 0
        eject = []
        excluderegex.each do |m|
          result.each do |k,|
            eject << k if k.match(m.gsub("\\\\"){"\\"})
          end
        end
        result.delete_if{|k,| eject.include? k }
      end

      if excludelist.count > 0
        result.delete_if{ |k,| excludelist.include? k }
      end

      result.each { |k, v|

        # Transform Time and True/False to integers
        v = v.to_i if v.is_a?(Time)
        v = 1 if v == true
        v = 0 if v == false

        member_type = get_member_type(status)

        metrics["#{prefix}#{replicaset}.#{member_type}.#{hostname}.#{k}"] = v
      }

        metrics.each_pair do |k,v|
          message = "#{k} #{v} #{timestamp}\n"
          printf "#{message}"
        end
       ok
    end
  end

end
