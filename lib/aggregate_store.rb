require 'json'

class AggregateStore
  attr_accessor :store

  def initialize(cache_file = nil)
    @store = {}
    @cache_file = cache_file
  end

  def increment_stream_ctr(event_hash)
    stream = event_hash[:stream]
    init_stream(stream) if !@store[stream]
    event = event_hash[:event]
    date = event_hash[:date]
    update_accounts_ctr(stream, event_hash[:account_id], date, event)
    update_users_ctr(stream, event_hash[:user_id], date, event)
  end

  def dump_aggregate_counters
    File.write(@cache_file, @store.to_json) if(@cache_file)
  end

  def reload_aggregate_counters
    if(@cache_file && File.exist?(@cache_file))
      aggregate_ctr_json = File.read(@cache_file)
      @store = JSON.parse(aggregate_ctr_json)
    end
  end

  private

  def init_stream(stream)
    @store[stream] = {
      "accounts" => {},
      "stream" => stream,
      "users" => {}
    }
  end

  def update_accounts_ctr(stream, account_id, date, event)
    stream_ctr = @store[stream]
    account = Account.where(:stream => stream, :account_id => account_id).first
    stream_ctr["accounts"][account.status] ||= {}
    stream_ctr["accounts"][account.status][date] ||= {}
    stream_ctr["accounts"][account.status][date][event] ||= 0
    stream_ctr["accounts"][account.status][date][event] += 1
  end

  def update_users_ctr(stream, user_id, date, event)
    stream_ctr = @store[stream]
    user = User.where(:stream => stream, :user_id => user_id).first
    stream_ctr["users"][user.role] ||= {}
    stream_ctr["users"][user.role][date] ||= {}
    stream_ctr["users"][user.role][date][event] ||= 0
    stream_ctr["users"][user.role][date][event] += 1
  end

end