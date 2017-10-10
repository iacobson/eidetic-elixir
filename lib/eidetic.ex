defmodule Eidetic do
  @moduledoc """
  Configure an adapter for the eventstore:

  ```elixir
  # Example with GenServer Adapter
  config :eidetic, eventstore_adapter: Eidetic.EventStore.GenServer
  ```

  Configure subscribers, if required:

  ```elixir
  config :eidetic, eventstore_subscribers: [YourSubscribers]
  ```

  Add Eidetic to your supervisor tree:

  ```elixir
  supervisor(Eidetic, []),
  ```
  """

  use Supervisor
  require Logger

  @doc false
  def start_link do
    Logger.info fn()  -> "Starting :eidetic" end
    Supervisor.start_link(__MODULE__, %{
        adapter: Application.get_env(:eidetic, :eventstore_adapter),
        subscribers: Application.get_env(:eidetic, :eventstore_subscribers)
        }, [name: :eidetic])
  end

  @doc false
  def init(state = %{adapter: adapter, subscribers: subscribers}) do
    Logger.debug fn() -> "  - with :adapter #{adapter}" end
    Logger.debug fn() -> "  - with :subscribers #{inspect subscribers}" end

    children = [
      worker(Eidetic.EventStore, [state]),
      worker(adapter, [[name: :eidetic_eventstore_adapter]])
    ] ++ Enum.map(subscribers, fn(subscriber) ->
      worker(subscriber, [name: subscriber])
    end)

    supervise(children, strategy: :one_for_one)
  end
end
