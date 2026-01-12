require 'thread'
require 'feedjira'
require 'active_support/core_ext/string/inflections'
require 'httparty'

# Simple class to retrieve, cache and filter results of RSS feeds using Feedjira
class RSSCache

  DEFAULT_OPTIONS = {
    :timeout_secs => 60*60,
    :poll_secs => 60,
    :filter => lambda {|entries| return entries}
  }

  def initialize url, options = {}

    @url = url
    @last_updated = nil
    @entries = nil
    @lock = Mutex.new

    @options = DEFAULT_OPTIONS.merge(options)

    Thread.new do
      begin
        while true do
          self.update false
          sleep @options[:poll_secs]
        end
      rescue Exception => ex
        backtrace = ex.backtrace.join("\n")
        puts "#{Time.now.to_formatted_s :db} :: Exception thrown in RSSCache Thread loop :: #{ex.message}\n#{backtrace}"
      end
    end
  end

  def update jit_update
    @lock.synchronize do
      if @last_updated.nil? or @last_updated < Time.now - @options[:timeout_secs]
        puts "#{Time.now.to_formatted_s :db} :: RSSCache Update #{jit_update ? '(JIT) ' : ''}:: #{@url} :: Fetching RSS\n"
        begin
          feed_xml = HTTParty.get(@url).body
          feed_result = Feedjira.parse(feed_xml)
        rescue Exception => ex
          puts "#{Time.now.to_formatted_s :db} :: RSSCache Update #{jit_update ? '(JIT) ' : ''}:: #{@url} :: Exception raised - #{ex.message}\n"
        end
        # Belt and braces check that we've actually been given back a Feedjira Parser class and not a Fixnum
        # or perhaps something else entirely, depending on what Feedjira felt like returning (seems to return
        # HTTP status code as a Fixnum when parsing fails)
        if not feed_result.nil? and Feedjira::Parser.constants.include? feed_result.class.name.demodulize.to_sym
          raw_entries = feed_result.entries
          @entries = @options[:filter].call raw_entries unless raw_entries.size == 0
          @last_updated = Time.now unless @entries.nil? or @entries.size == 0
          puts "#{Time.now.to_formatted_s :db} :: RSSCache Update #{jit_update ? '(JIT) ' : ''}:: #{@url} :: Success - will cache for #{@options[:timeout_secs]} seconds\n"
        else
          puts "#{Time.now.to_formatted_s :db} :: RSSCache Update #{jit_update ? '(JIT) ' : ''}:: #{@url} :: Fail - result was #{feed_result.nil? ? 'nil' : feed_result}\n"
        end
      end
    end
  end

  def get
    self.update true
    @entries || []
  end

end
