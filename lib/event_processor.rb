class EventProcessor
  #tbd_cached_event_ids need to be destroyed after the chunk is processed
  attr_accessor :aggregate_store, :tbd_cached_event_ids

  def initialize(counter_cache_file)
    @aggregate_store = ::AggregateStore.new(counter_cache_file)
    @tbd_cached_event_ids = []
  end

  def process(message)
    if is_event?(message)
      process_event(message)
    else
      process_id(message)
    end
  end

  private

  def process_id(message)
    identification = ::Identification.new(message)
    identification.save!

    events_to_update = CachedEvent.where(:stream => message["stream"],
                                   :user_id => message["userId"])
    events_to_update.each do |cached_event|
      # This check to handle the case where we get duplicate identification messages
      if(!@tbd_cached_event_ids.include?(cached_event.id))
        event_hash =  { :account_id => cached_event.account_id,
                        :user_id => cached_event.user_id,
                        :stream => cached_event.stream,
                        :event => cached_event.event,
                        :date => cached_event.date
                      }
        @aggregate_store.increment_stream_ctr(event_hash)
        @tbd_cached_event_ids << cached_event.id
      end
    end
  end

  def process_event(message)
    event_hash =  { :account_id => message["accountId"],
                    :user_id => message["userId"],
                    :stream => message["stream"],
                    :event => message["event"],
                    :date => format_date(message["timestamp"])
                  }
    if ::Identification.user_exists?(message)
      @aggregate_store.increment_stream_ctr(event_hash)
    else
      ::Event.new(event_hash).save!
    end
  end

  def format_date(timestamp)
    DateTime.strptime(timestamp.to_s,'%Q').strftime('%F')
  end

  def is_event?(message)
    message["userData"] == nil
  end

end