defmodule Eidetic.Meta do
  @moduledoc :false

  defstruct identifier: nil,
    serial_number: 0,
    created_at: nil,
    last_modified_at: nil,
    uncommitted_events: []
end
