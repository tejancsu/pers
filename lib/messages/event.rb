class Event
  def initialize(event_hash)
    @cached_event = CachedEvent.new(event_hash)
  end

  def save!
    @cached_event.save!
  end
end