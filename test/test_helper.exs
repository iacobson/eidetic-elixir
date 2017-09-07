Application.put_env(:eidetic, :eventstore_adapter, Eidetic.EventStore.GenServer)
Application.put_env(:eidetic, :eventstore_subscribers, [Example.Subscriber.Config])

Eidetic.start_link()
ExUnit.start()
