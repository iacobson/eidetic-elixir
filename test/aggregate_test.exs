defmodule Test.Eidetic.Aggregate do
  use ExUnit.Case

  @user_events %{
    registered: %Eidetic.Event{
      type: "UserRegistered",
      version: 1,
      serial_number: 1,
      datetime: DateTime.utc_now(),
      payload: %{
        forename: "Darrell",
        surname: "Abbott"
      }
    },
    renamed: %Eidetic.Event{
      type: "UserRenamed",
      version: 1,
      serial_number: 2,
      datetime: DateTime.utc_now(),
      payload: %{
        forename: "Dimebag",
        surname: "Darrell"
      }
    },
    unhandled: %Eidetic.Event{
      type: "UserChangedTheirName",
      version: 2,
      serial_number: 1,
      datetime: DateTime.utc_now(),
      payload: %{
        forename: "Dimebag",
        surname: "Darrell"
      }
    }
  }

  test "Can create a new User" do
    user = Example.User.register(forename: "Darrell", surname: "Abbott")

    assert %Example.User{forename: "Darrell", surname: "Abbott"} = user
  end

  test "Can load a user from a single event" do
    user = Example.User.load(UUID.uuid4(), Map.get(@user_events, :registered))

    assert %Example.User{forename: "Darrell", surname: "Abbott"} = user
    assert %Example.User{meta: %Eidetic.Meta{serial_number: 1}} = user
    assert %Example.User{meta: %Eidetic.Meta{uncommitted_events: []}} = user
  end


  test "Can load a user from a list of events" do
    list_of_events = [Map.get(@user_events, :registered), Map.get(@user_events, :renamed)]

    user = Example.User.load("my-identifier", list_of_events)

    assert %Example.User{forename: "Dimebag", surname: "Darrell"} = user
    assert %Example.User{meta: %Eidetic.Meta{serial_number: 2}} = user
    assert %Example.User{meta: %Eidetic.Meta{uncommitted_events: []}} = user
  end

  test "Will raise an error if there is an event that the aggregate cannot handle" do
    assert_raise RuntimeError, ~r/^Unsupported event/, fn -> Example.User.load(UUID.uuid4(), Map.get(@user_events, :unhandled)) end
  end

  test "Can return the identifier when asked" do
    identifier = UUID.uuid4()

    aggregate = Example.User.load(identifier, Map.get(@user_events, :registered))

    assert aggregate.meta.identifier == identifier
    assert [uuid: _, binary: _,  type: _, version: 4, variant: _] = aggregate
      |> Example.User.identifier()
      |> UUID.info!
  end

  test "it handles created_at and last_modified_at dates" do
    user = Example.User.register(forename: "Darrell", surname: "Abbott")

    assert DateTime.to_unix(DateTime.utc_now()) - DateTime.to_unix(Example.User.created_at(user)) < 1

    # Ensure the renmae event is atleast 1 second after the register
    :timer.sleep(1000)

    updated_user = Example.User.rename(user, forename: "Dimebag", surname: "Darrell")

    assert DateTime.to_unix(Example.User.created_at(user)) < DateTime.to_unix(Example.User.last_modified_at(updated_user))
  end

  test "Will return an updated aggregate and a list of events to be persisted during commit" do
    aggregate = Example.User.register(forename: "Darrell", surname: "Abbott")

    {new_aggregate, events} = Example.User.commit(aggregate)

    assert new_aggregate.meta.uncommitted_events == []
    assert length(events)
  end

  test "It correctly manages the identifier and serial_number on the events" do
    {aggregate, events} = Example.User.register(forename: "Darrell", surname: "Abbott")
      |> Example.User.rename(forename: "Dimebag", surname: "Darrell")
      |> Example.User.commit()

    require Logger

    assert length(events) == 2

    event1 = List.first(events)
    event2 = List.last(events)

    assert event1.identifier == event2.identifier
    assert event1.serial_number == 1
    assert event2.serial_number == 2
  end

  end
