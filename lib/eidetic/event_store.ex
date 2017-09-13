defmodule Eidetic.EventStore do
  @moduledoc """
  This module manages loading / saving from / to the EventStore.

  Configuring:

  ```elixir
  confing :eidetic eventstore_adapter: Some.Adapter
  ```

  Using:

  ```elixir
  {:ok, aggregate} = Eidetic.save(an_aggregate)

  # or
  aggregate = Eidetic.save!(aggregate)
  ```
  """

  use GenServer
  alias Eidetic.Aggregate
  alias Eidetic.Event
  require Logger

  @callback handle_call({:record, %Event{}}, pid, Map)
    :: {:ok, [object_identifier: String.t]}

  @callback handle_call({:fetch, String.t}, pid, Map)
    :: {:ok, [events: [%Event{}]]}

  @callback handle_call({:fetch_until, String.t, pos_integer()}, pid, Map)
    :: {:ok, [events: [%Event{}]]}

  @spec save(map())
    :: {:ok, map()}
  @spec save!(map())
    :: map()

  @spec load(atom(), binary())
    :: {:ok, map()}
  @spec load!(atom(), binary())
    :: map()

  @spec add_subscriber(atom())
    :: any()

  @doc false
  def start_link(state = %{adapter: adapter, subscribers: subscribers}) do
    GenServer.start_link(__MODULE__, state, [name: :eidetic_eventstore])
  end

  @doc false
  def init(state = %{adapter: adapter, subscribers: subscribers}) do
    {:ok, state}
  end

  @doc """
  Save an %Eidetic.Aggregate{}'s uncommitted events to the EventStore
  """
  def save(aggregate) do
    GenServer.call(:eidetic_eventstore, {:save, aggregate})
  end

  @doc """
  Save an %Eidetic.Aggregate{}'s uncommitted events to the EventStore, only returning the aggregate.

  Eventually this will raise an error when a write / transaction fails.
  """
  def save!(aggregate) do
    {:ok, aggregate} = save(aggregate)

    aggregate
  end

  def handle_call({:save, aggregate}, _from, state = %{subscribers: subscribers}) do
    # GenServer.cast(:eventstore_adapter, {:start_transaction})
    for event <- aggregate.meta.uncommitted_events do
      GenServer.call(:eidetic_eventstore_adapter, {:record, event})
    end
    # :ok = GenServer.cast(:eventstore_adapter, {:end_transaction})

    # Transaction didn't fail, publish
    for event <- aggregate.meta.uncommitted_events do
      for subscriber <- subscribers do
          Logger.debug fn ->
              "Publishing to subscriber #{inspect subscriber}"
          end
          GenServer.cast(subscriber, {:publish, event})
      end
    end

    {:reply,
      {
        :ok,
        %{aggregate | meta: Map.put(aggregate.meta, :uncommitted_events, [])}
      },
      state}
  end

  @doc """
  Load events from the EventStore and produce an aggregate
  """
  def load(type, identifier) do
    GenServer.call(:eidetic_eventstore, {:load, type, identifier})
  end

  @doc """
  Load events, to a particular version, from the EventStore and produce an aggregate
  """
  def load(type, identifier, [version: version]) do
    GenServer.call(:eidetic_eventstore, {:load, type, identifier, version})
  end

  @doc """
  Load events from the EventStore and produce a aggregate, only returning the aggregate.
  """
  def load!(type, identifier) do
    {:ok, aggregate = %type{}} = load(type, identifier)

    aggregate

  rescue
    error in MatchError
      -> reraise RuntimeError, ~s/Could not find an aggregate with identifier
        "#{identifier}" and type #{type}/, System.stacktrace()

    error
      -> reraise ~s/Unexpected error loading aggregate: #{inspect error}/,
        System.stacktrace()
  end

  @doc """
  Load events, to a particular version, from the EventStore and produce a
    aggregate, only returning the aggregate.
  """
  def load!(type, identifier, [version: version]) do
    {:ok, aggregate = %type{}} = load(type, identifier, [version: version])

    aggregate

  rescue
    error in MatchError
      -> reraise RuntimeError, ~s/Could not find an aggregate with identifier
        "#{identifier}" and type #{type}/, System.stacktrace()

    error
      -> reraise ~s/Unexpected error loading aggregate: #{inspect error}/,
        System.stacktrace()
  end

  def handle_call({:load, type, identifier}, _from, state) do
    with {:ok, events} when is_list(events)
      <- GenServer.call(:eidetic_eventstore_adapter, {:fetch, identifier})
    do
      {:reply, {:ok, type.load(identifier, events)}, state}
    else
      _
        -> {:reply, :aggregate_does_not_exist, state}
    end
  end

  def handle_call({:load, type, identifier, version}, _from, state) do
    with {:ok, events} when is_list(events)
      <- GenServer.call(:eidetic_eventstore_adapter, {:fetch_until, identifier, version})
    do
      {:reply, {:ok, type.load(identifier, events)}, state}
    else
      _
        -> {:reply, :aggregate_does_not_exist, state}
    end
  end

  def add_subscriber(subscriber) do
    GenServer.cast(:eidetic_eventstore, {:add_subscriber, subscriber})
  end

  def handle_cast({:add_subscriber, subscriber}, state = %{subscribers: subscribers}) do
    {:noreply, %{subscribers: subscribers ++ [subscriber]}}
  end
end
