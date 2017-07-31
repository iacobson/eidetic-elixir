defmodule Eidetic.Meta do
  defstruct identifier: nil,
    serial_number: 0,
    created_at: nil,
    last_modified_at: nil,
    uncommitted_events: []
end
