require 'pp'

CHUNK_SIZE = 10000

class EventAnalytics
  def initialize(file_name, counter_cache_file, processing_state_file, is_retry)
    @file = File.open(file_name)
    @event_processor = EventProcessor.new(counter_cache_file)
    @processing_state_file = processing_state_file
    @is_retry = is_retry
  end

  def get_aggregates!
    if @is_retry
      move_file_ptr!
      @event_processor.aggregate_store.reload_aggregate_counters
    end

    ctr = 0
    @file.each_line do |line|
      message = JSON.parse(line)
      @event_processor.process(message)
      ctr += 1
      if(ctr == CHUNK_SIZE)
        update_processing_state!
        ctr = 0
      end
    end
    store_state = @event_processor.aggregate_store.store
    pp store_state
  end

  def move_file_ptr!
    if File.exists?(@processing_state_file)
      prev_pos = File.read(@processing_state_file).to_i
      @file.seek(prev_pos)
    end
  end

  def update_processing_state!
    #This is to make sure if the process is killed while updating the processing state,
    #we can do the whole processing again from the beginning
    File.delete(@processing_state_file) if File.exist?(@processing_state_file)
    @event_processor.aggregate_store.dump_aggregate_counters
    #delete all cached events that are already processed
    CachedEvent.where(id: @event_processor.tbd_cached_event_ids).delete_all
    File.write(@processing_state_file, @file.pos)
  end

end