defmodule Eidetic.Aggregate do
  require Logger
  alias Eidetic.Event
  alias Eidetic.Meta

  # credo:disable-for-this-file Credo.Check.Refactor.LongQuoteBlocks

  @moduledoc """
  This module is responsible for initialising new event sourced aggregates,
  and maintaining their meta data.

  To get started, simply add the following to your module:
  ```elixir
  use Eidetic.Aggregate, fields: [some_field: "default value"]
  ```

  In order to handle new events, you'll need to add `defp apply_event/2`
  functions:

  ```elixir
  defp apply_event(aggregate, event = %Eidetic.Event{type: "MyEventName", version: 1}) do
  ... your logic goes here...
  end
  ```
  """

  @doc false
  defmacro __using__(fields: fields) do
    quote do
      require Logger

      defstruct unquote(fields) ++ [meta: %Meta{}]

      @doc """
      Load a aggregate by providing the identifier and a list of events to process
      """
      def load(identifier, events) do
        Logger.debug fn ->
            "Loading #{__MODULE__} with identifier '#{identifier}'"
              <> " and events #{inspect events}"
        end

        aggregate = %__MODULE__{
          meta: %Meta{
            identifier: identifier
          }}
        |> initialise(events)

        {aggregate, _events} = commit(aggregate)

        aggregate
      end

      @doc """
      Get the identifier of your Eidetic Aggregate
      """
      def identifier(aggregate = %__MODULE__{}) do
        aggregate.meta.identifier
      end

      @doc """
      Get the `serial_number` for your aggregate.

      If you have a aggregate which was constructed from 2 events, you will receive 2
      """
      def serial_number(aggregate = %__MODULE__{}) do
        aggregate.meta.serial_number
      end

      @doc """
      Get the date and time of when this aggregate was created
      """
      def created_at(aggregate = %__MODULE__{}) do
        aggregate.meta.created_at
      end

      @doc """
      Get the date and time of when this aggregate was last modified
      """
      def last_modified_at(aggregate = %__MODULE__{}) do
        aggregate.meta.last_modified_at
      end

      @doc """
      By calling `commit`, you will receive the uncommitted events (to put in your event store)
      and the new aggregate

      ## Example
      ```elixir
      {%Example.User{}, [%Eidetic.Event{}]} = Example.Person.commit(my_person)
      ```
      """
      def commit(aggregate = %__MODULE__{}) do
        Logger.debug fn ->
          "Committing events for '#{__MODULE__}'"
            <> " (Identifier: '#{aggregate.meta.identifier}'), "
            <> "with uncommitted events: "
            <> "#{inspect aggregate.meta.uncommitted_events}"
        end

        {
          %{aggregate | meta: Map.put(aggregate.meta, :uncommitted_events, [])},
          aggregate.meta.uncommitted_events
        }
      end

      defp initialise do
        Logger.debug fn -> "Creating a new #{__MODULE__}" end

        %__MODULE__{}
      end

      defp initialise(aggregate = %__MODULE__{}, [head | tail]) do
        Logger.debug fn ->
          "Rebuilding '#{__MODULE__}' (identifier: '#{identifier(aggregate)}') "
            <> "with events #{inspect [head] ++ tail}"
      end

        aggregate
        |> _apply_event(head)
        |> initialise(tail)
      end

      defp initialise(aggregate = %__MODULE__{}, []) do
        Logger.debug fn ->
            "Completed rebuild of '#{__MODULE__}' "
              <> "(Identifier: '#{identifier(aggregate)}')"
        end

        aggregate
      end

      defp initialise(aggregate = %__MODULE__{}, event = %Event{}) do
        Logger.debug fn ->
            "Applying a single event to '#{__MODULE__}' "
              <> "(Identifier: '#{identifier(aggregate)}')"
              <> ". Event is #{inspect event}"
        end

        _apply_event(aggregate, event)
      end

      @doc false
      defp emit(type: type, version: version, payload: payload) do
        aggregate = %__MODULE__{meta: %Meta{identifier: UUID.uuid4()}}

        Logger.debug fn ->
            "Event Emitted with no aggregate. Generating '#{__MODULE__}' "
              <> "with identifier '#{identifier(aggregate)}'"
        end

        emit aggregate: aggregate,
          type: type, version: version, payload: payload
      end

      @doc false
      defp emit(aggregate: aggregate = %__MODULE__{}, type: type, version: version, payload: payload) do
        Logger.debug fn ->
            "Event Emitted from '#{__MODULE__}' "
              <> "(identifier: #{identifier(aggregate)}, type: #{type}, "
              <> "version: #{version}, payload: #{inspect payload})"
        end

        event = %Event{
          identifier: identifier(aggregate),
          serial_number: serial_number(aggregate) + 1,
          type: type,
          version: version,
          payload: payload,
          datetime: DateTime.utc_now()
        }

        _apply_event(aggregate, event)
      end

      defp _apply_event(aggregate, events) when is_list(events) do
        Enum.reduce(events, aggregate, fn(event, aggregate) ->
          _apply_event(event, aggregate)
        end)
      end

      defp _apply_event(aggregate = %__MODULE__{meta: %Meta{created_at: nil}}, event = %Event{}) do
        aggregate
        |> Map.put(:meta, %{aggregate.meta | created_at: event.datetime})
        |> _apply_event(event)
      end

      defp _apply_event(aggregate = %__MODULE__{}, event = %Event{}) do
        aggregate = Map.put(aggregate, :meta, %{
          aggregate.meta |
            serial_number: event.serial_number,
            uncommitted_events: aggregate.meta.uncommitted_events ++ [event],
            last_modified_at: event.datetime
        })

        try do
          apply_event(aggregate, event)
        rescue
            error -> reraise RuntimeError,
              "Unsupported event: #{event.type}, version #{event.version}",
              System.stacktrace()
        end

      end

      @doc false
      defp apply_event("Never gonna give you up", "Never gonna let you down") do
        raise RuntimeError, message: "Or hurt you"
      end
    end
  end
end
