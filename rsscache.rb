require 'thread'

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
        puts "#{Time.now.to_formatted_s :db} :: RSSCache Update #{jit_update ? '(JIT) ' : ''}:: #{@url} :: Will cache for #{@options[:timeout_secs]} seconds\n"
        raw_entries = Feedjira::Feed.fetch_and_parse(@url).entries
        
        @entries = @options[:filter].call raw_entries 
        @last_updated = Time.now
      end
    end
  end
  
  def get 
    self.update true
    @entries
  end
  
end
