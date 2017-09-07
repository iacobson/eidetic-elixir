defmodule Test.Eidetic.EventStore do
  use ExUnit.Case, async: false

  test "It can save and load aggregates" do
    user =
      [forename: "Darrell", surname: "Abbott"]
      |> Example.User.register()
      |> Eidetic.EventStore.save!()

    loaded_user = Eidetic.EventStore.load!(Example.User, Example.User.identifier(user))

    assert user == loaded_user

    assert user.forename == "Darrell"
    assert user.surname == "Abbott"
  end

  test "it can handle aggregates that do no exist" do
    assert :aggregate_does_not_exist = Eidetic.EventStore.load(Example.User, "fake-identifier")

    assert_raise RuntimeError,  ~r/^Could not find/, fn ->
       Eidetic.EventStore.load!(Example.User, "fake-identifier")
     end
  end

  test "It can add subscribers provided through configuration" do
    Process.register(self(), Example.Subscriber.Config)

    user = Example.User.register(forename: "Darrell", surname: "Abbott")
    {:ok, saved_user = %Example.User{}} = Eidetic.EventStore.save(user)

    for event <- user.meta.uncommitted_events do
      assert_received {:"$gen_cast", {:publish, event}}
    end
  end

  test "Subscribers receive events when added to EventStore" do
    Eidetic.EventStore.add_subscriber(Example.Subscriber)
    Process.register(self(), Example.Subscriber)

    user = Example.User.register(forename: "Darrell", surname: "Abbott")
    {:ok, saved_user} = Eidetic.EventStore.save(user)

    for event <- user.meta.uncommitted_events do
      assert_received {:"$gen_cast", {:publish, event}}
    end
  end
end
