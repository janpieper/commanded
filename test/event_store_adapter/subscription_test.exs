defmodule Commanded.EventStore.Adapter.SubscriptionTest do
  use Commanded.StorageCase
  use Commanded.EventStore

  alias Commanded.EventStore.EventData
  alias Commanded.ExampleDomain.BankAccount.Events.BankAccountOpened

  require Logger

  describe "subscribe to all streams" do
    test "should receive events appended to any stream" do
      {:ok, subscription} = @event_store.subscribe_to_all_streams("subscriber", self(), :origin)

      {:ok, 1} = @event_store.append_to_stream("stream1", 0, build_events(1))
      {:ok, 2} = @event_store.append_to_stream("stream2", 0, build_events(2))
      {:ok, 3} = @event_store.append_to_stream("stream3", 0, build_events(3))

      assert_receive_events(subscription, 1)
      assert_receive_events(subscription, 2)
      assert_receive_events(subscription, 3)

      refute_receive({:events, _events})
    end

    test "should prevent duplicate subscriptions" do
      {:ok, _subscription} = @event_store.subscribe_to_all_streams("subscriber", self(), :origin)
      assert {:error, :subscription_already_exists} == @event_store.subscribe_to_all_streams("subscriber", self(), :origin)
    end
  end

  describe "ubsubscribe from all streams" do
    test "should not receive further events appended to any stream" do
      {:ok, subscription} = @event_store.subscribe_to_all_streams("subscriber", self(), :origin)

      {:ok, 1} = @event_store.append_to_stream("stream1", 0, build_events(1))

      assert_receive_events(subscription, 1)

      :ok = @event_store.unsubscribe_from_all_streams("subscriber")

      {:ok, 2} = @event_store.append_to_stream("stream2", 0, build_events(2))
      {:ok, 3} = @event_store.append_to_stream("stream3", 0, build_events(3))

      refute_receive({:events, _events})
    end
  end

  def assert_receive_events(subscription, expected_count) do
    assert_receive {:events, received_events}
    assert length(received_events) == expected_count

    @event_store.ack_event(subscription, List.last(received_events))
  end

  # test "should catch-up from existing events"
  # test "should remember last seen event number when subscription resumes"

  defp build_event(account_number) do
    %EventData{
      correlation_id: UUID.uuid4,
      event_type: "Elixir.Commanded.ExampleDomain.BankAccount.Events.BankAccountOpened",
      data: %BankAccountOpened{account_number: account_number, initial_balance: 1_000},
      metadata: %{}
    }
  end

  defp build_events(count) do
    for account_number <- 1..count, do: build_event(account_number)
  end
end
