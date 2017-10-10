defmodule Example.Subscriber.Config do
  @moduledoc false
  use GenServer

  @doc false
  def start_link(_) do
    GenServer.start_link(__MODULE__, %{})
  end
end
