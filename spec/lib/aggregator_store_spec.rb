require 'spec_helper'

describe "#AggregateStore" do
  before :each do
    @cache_file = ".aggregator_spec_tmp"
    @store = AggregateStore.new(@cache_file)
    @event_hash = { date:"2015-06-02", stream: "frontleaf", user_id: "U1", account_id: "A1", event: "login"}
    @account = double("account", :status => "paying")
    @user = double("user", :role => "admin")
    @store_state = {"frontleaf"=>{"accounts"=>{"paying"=>{"2015-07-15"=>{"login"=>143, "clicked_something"=>1494}}}, "stream"=>"frontleaf", "users"=>{"admin"=>{"2015-07-15"=>{"login"=>73, "clicked_something"=>291}}}}}
  end

  describe "#increment_stream_ctr" do
    it 'should update store state as expected' do
      expect(@store).to receive(:update_accounts_ctr).with(@event_hash[:stream],
       @event_hash[:account_id], @event_hash[:date], @event_hash[:event])
      expect(@store).to receive(:update_users_ctr).with(@event_hash[:stream],
       @event_hash[:user_id], @event_hash[:date], @event_hash[:event])
      @store.send(:increment_stream_ctr, @event_hash)
    end
  end

  describe "#update_accounts_ctr" do
    it 'should update store state as expected' do
      allow(Account).to receive(:where).with({ stream: "frontleaf", account_id: "A1" }).and_return([@account])
      @store.send(:init_stream, "frontleaf")
      @store.send(:update_accounts_ctr, @event_hash[:stream],
       @event_hash[:account_id], @event_hash[:date], @event_hash[:event])
      @store_state = @store.instance_variable_get(:@store)
      expect(@store_state.keys.size).to eq(1)
      expect(@store_state["frontleaf"]).not_to be_nil
      expect(@store_state["frontleaf"]["stream"]).to eq("frontleaf")
      expect(@store_state["frontleaf"]["accounts"]).to_not be_nil
      expect(@store_state["frontleaf"]["users"]).to be_empty
      expect(@store_state["frontleaf"]["accounts"]["paying"]["2015-06-02"]).to_not be_nil
      expect(@store_state["frontleaf"]["accounts"]["paying"]["2015-06-02"]["login"]).to eq(1)
    end
  end

  describe "#update_users_ctr" do
    it 'should update store state as expected' do
      allow(User).to receive(:where).with({ stream: "frontleaf", user_id: "U1" }).and_return([@user])
      @store.send(:init_stream, "frontleaf")
      @store.send(:update_users_ctr, @event_hash[:stream],
       @event_hash[:user_id], @event_hash[:date], @event_hash[:event])
      @store_state = @store.instance_variable_get(:@store)
      expect(@store_state.keys.size).to eq(1)
      expect(@store_state["frontleaf"]).not_to be_nil
      expect(@store_state["frontleaf"]["stream"]).to eq("frontleaf")
      expect(@store_state["frontleaf"]["users"]).to_not be_nil
      expect(@store_state["frontleaf"]["accounts"]).to be_empty
      expect(@store_state["frontleaf"]["users"]["admin"]["2015-06-02"]).to_not be_nil
      expect(@store_state["frontleaf"]["users"]["admin"]["2015-06-02"]["login"]).to eq(1)
    end
  end

  describe "#dump_aggregate_counters" do
    it "dumps hash to file" do
      allow(File).to receive(:write).with(@cache_file, @store_state.to_json)
      @store.instance_variable_set(:@store, @store_state)
      @store.dump_aggregate_counters
    end
  end

  describe "#reload_aggregate_counters" do
    it "reads json from file" do
      allow(File).to receive(:read).with(@cache_file).and_return(@store_state.to_json)
      File.stub(:exist?).and_call_original
      File.stub(:exist?).with(@cache_file).and_return(true)
      expect(@store.store).to be_empty
      @store.reload_aggregate_counters
      expect(@store.store).to eq(@store_state)
    end
  end
end