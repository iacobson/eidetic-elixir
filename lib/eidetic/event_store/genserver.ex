defmodule Eidetic.EventStore.GenServer do
  @moduledoc false
  @behaviour Eidetic.EventStore

  use GenServer
  require Logger

  @doc false
  def start_link(options \\ []) do
    GenServer.start_link(__MODULE__, %{}, options)
  end

  @doc false
  def handle_call({:record, event = %Eidetic.Event{}}, _from, state) do
    Logger.debug fn ->
        "Updating state #{inspect state} with #{inspect event}"
    end

    {:reply,
      [object_identifier: event.identifier
        <> ":" <> Integer.to_string(event.serial_number)
      ],
      Map.update(state, event.identifier, [event], &(&1 ++ [event]))
    }
  end

  @doc false
  def handle_call({:fetch, identifier}, _from, state) do
    Logger.debug fn ->
      "Looking for #{identifier} in state #{inspect state}"
    end

    {:reply, {:ok, Map.get(state, identifier, nil)}, state}
  end

  @doc false
  def handle_call({:fetch_until, identifier, version}, _from, state) do
    Logger.debug fn ->
      "Looking for #{identifier} in state #{inspect state}, until version #{version}"
    end

    events = state
    |> Map.get(identifier, nil)
    |> Enum.filter(fn(event) ->
      version >= event.serial_number
    end)

    Logger.debug fn() -> "Returning events #{inspect events}" end

    {:reply, {:ok, events}, state}
  end
end
