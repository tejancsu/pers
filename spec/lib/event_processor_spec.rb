require 'spec_helper'

describe "#EventProcessor" do
  before :each do
    @aggregate_store = double("aggregate_store")
    allow(::AggregateStore).to receive(:new).and_return(@aggregate_store)

    @event_processor = EventProcessor.new
    @id_message = JSON.parse '{
                                    "timestamp": 1437055157310,
                                    "stream": "frontleaf",
                                    "userId": "U1",
                                    "userName": "greg.mcguire@zuora.com",
                                    "userData": {
                                      "role": "admin"
                                    },
                                    "accountId": "A1",
                                    "accountName": "Zuora",
                                    "accountData": {
                                      "status": "paying",
                                      "plan": "enterprise"
                                    }
                                  }'
    @event_message = JSON.parse '{
                                    "timestamp": 1437055155340,
                                    "stream": "frontleaf",
                                    "userId": "U1",
                                    "accountId": "A1",
                                    "event": "login"
                                 }'

    @cached_event1 = double("cashed_event1",:account_id => "A1",
                                            :user_id => "U1",
                                            :stream => "frontleaf",
                                            :event => "click",
                                            :date => "2015-05-31")
  end

  describe "#process" do
    context "message is event" do
      it "should call process_event method" do
        allow(@event_processor).to receive(:process_event).with(@event_message)
        @event_processor.process(@event_message)
      end
    end

    context "message is identification" do
      it "should call process_id method" do
        allow(@event_processor).to receive(:process_id).with(@id_message)
        @event_processor.process(@id_message)
      end
    end
  end

  describe "#process_id" do
    context "user does not exists" do
      before do
          allow(::Identification).to receive(:user_exists?)
                                  .with(@id_message).and_return(false)
          expect(::Identification).to receive(:user_exists?)
                                  .with(@id_message)
      end

      context "cached events are empty" do
        before do
          allow(CachedEvent).to receive(:where).and_return([])
        end

        it 'saves identification' do
          identification_mock = instance_double(Identification, :save! => true)
          allow(::Identification).to receive(:new).and_return(identification_mock)
          expect(identification_mock).to receive(:save!)
          @event_processor.send(:process, @id_message)
        end
      end

      context "cached events are not empty" do
        before do
          allow(CachedEvent).to receive(:where).with({stream: "frontleaf",
                                                      user_id: "U1"})
                                               .and_return([@cached_event1])
          expect(CachedEvent).to receive(:where).with({stream: "frontleaf",
                                                      user_id: "U1"})
        end

        it 'saves identification and calls increment counter' do
          identification_mock = instance_double(Identification, :save! => true)
          allow(::Identification).to receive(:new).and_return(identification_mock)
          expect(identification_mock).to receive(:save!)

          event_hash = { :account_id => @cached_event1.account_id,
                         :user_id => @cached_event1.user_id,
                         :stream => @cached_event1.stream,
                         :event => @cached_event1.event,
                         :date => @cached_event1.date
                       }

          allow(@aggregate_store).to receive(:increment_stream_ctr)
                                      .with(event_hash).and_return(nil)
          expect(@aggregate_store).to receive(:increment_stream_ctr)
                                      .with(event_hash)
          @event_processor.send(:process, @id_message)
        end
      end
    end

    context "user exists" do
      before do
          allow(::Identification).to receive(:user_exists?)
                                  .with(@id_message).and_return(true)
          expect(::Identification).to receive(:user_exists?)
                                  .with(@id_message)
      end

      it 'does nothing' do
        expect(::Identification).not_to receive(:new)
        @event_processor.send(:process, @id_message)
      end
    end
  end

  describe "#process_event" do
    context "user does not exists" do
      before do
          allow(::Identification).to receive(:user_exists?)
                                  .with(@event_message).and_return(false)
          expect(::Identification).to receive(:user_exists?)
                                  .with(@event_message)
      end

      it 'does not increment counter but stores event' do
        expect(::Identification).not_to receive(:increment_stream_ctr)
        event_mock = double("event", :save! => true)
        allow(::Event).to receive(:new).and_return(event_mock)
        expect(::Event).to receive(:new)
        expect(event_mock).to receive(:save!)
        @event_processor.send(:process_event, @event_message)
      end
    end

    context "user exists" do
      before do
          allow(::Identification).to receive(:user_exists?)
                                  .with(@event_message).and_return(true)
          expect(::Identification).to receive(:user_exists?)
                                  .with(@event_message)
      end

      it 'increments counter' do
        allow(@aggregate_store).to receive(:increment_stream_ctr)
        expect(@aggregate_store).to receive(:increment_stream_ctr)
        @event_processor.send(:process_event, @event_message)
      end
    end
  end
end