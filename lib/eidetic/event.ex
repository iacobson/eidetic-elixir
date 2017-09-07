defmodule Eidetic.Event do
  @moduledoc :false

  defstruct identifier: nil,
    serial_number: nil,
    type: nil,
    version: nil,
    payload: nil,
    metadata: %{},
    datetime: nil
end
