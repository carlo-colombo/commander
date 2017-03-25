defmodule CommanderTest do
  use ExUnit.Case
  doctest Commander

  def unwatch(_), do: {:unwatch}
  def stop(_, args), do: {:stop, args}
  def watch(_, arg1, arg2), do: {:watch, arg1, arg2}
  def error_handler(_,_,_), do: :error_handler
  def search(_, q) do
    IO.inspect("Search #{q}")
    {:search, q}
  end

  defmodule TestAPI2 do
    use Commander

    dispatch to: CommanderTest, handler: :entry_point do
      command "/unwatch"
      command "/watch", [:stop, :line]
      command "/stop", [:stop]
    end
  end

  defmodule TestAPI3 do
    use Commander

    dispatch to: CommanderTest, handler: :entry_point  do
      command "/unwatch"
      command "/stop", [:stop]
      command "/watch", [:stop, :line]

      on_error :error_handler
    end
  end

  defmodule TestAPI4 do
    use Commander

    dispatch to: CommanderTest, handler: :entry_point  do
      command "/search", [:q]

      on_error :error_handler
    end
  end

  test "compile and generate a entry_point/1 function" do
    defmodule TestAPI1 do
      use Commander

      dispatch to: CommanderTest, handler: :entry_point do
        command "/unwatch", []
      end
    end

    assert [entry_point: 1] = TestAPI1.__info__(:functions)
  end

  test "dispatch function depending on text" do

    assert make_message("/unwatch")
    |> TestAPI2.entry_point == {:ok, {:unwatch}}

    assert make_message("/stop 350")
    |> TestAPI2.entry_point == {:ok, {:stop, "350"}}
  end

  test "handling space inside a command with a single argument" do
    assert make_message("/search upper camden lower")
    |> TestAPI4.entry_point == {:ok, {:search, "upper camden lower"}}
  end

  test "handling space inside a command with a single argument, trim space around" do
    assert make_message("/search             upper camden lower  ")
    |> TestAPI4.entry_point == {:ok, {:search, "upper camden lower"}}
  end

  test "handling multiple spaces" do

    assert make_message("/unwatch     ")
    |> TestAPI2.entry_point == {:ok,{:unwatch}}

    assert make_message("/stop    350")
    |> TestAPI2.entry_point == {:ok,{:stop, "350"}}

    assert make_message("/stop    350   ")
    |> TestAPI2.entry_point == {:ok,{:stop, "350"}}

    assert make_message("/watch    350      44  ")
    |> TestAPI2.entry_point == {:ok,{:watch, "350", "44"}}
  end

  test "handling dispatcing errors, existing command wrong arguments" do

    assert {:error, _} = make_message("/unwatch   350  ")
    |> TestAPI3.entry_point

    assert {:error, _} = make_message("/stop   ")
    |> TestAPI3.entry_point

    assert {:error, _} = make_message("/watch 350")
    |> TestAPI3.entry_point

    assert {:error, _} = make_message("/watch 350 450 500")
    |> TestAPI3.entry_point
  end

  test "handling errors, inexistent command should be ignored" do
    {:ok, _} = make_message("/whatisthis   350  ")
    |> TestAPI3.entry_point
  end

  test "handling errors, not a text" do
    {:error, _} = TestAPI3.entry_point(%{"message" => %{"chat" => %{"id" => -138892, "title" => "Dublin bus", "type" => "group"}, "date" => 1464731615, "from" => %{"first_name" => "Carlo", "id" => 23338, "last_name" => "Colombo", "username" => "caoclmb"}, "message_id" => 458, "new_chat_member" => %{"first_name" => "Dublin Bus Bot", "id" => 27077, "username" => "dublin_bus_bot"}, "new_chat_participant" => %{"first_name" => "Dublin Bus Bot", "id" => 239397, "username" => "dublin_bus_bot"}}, "update_id" => 35283})


  end

  test "handling message with callback_data" do
    msg = %{callback_query: %{chat_instance: "-5308050",
                                          data: "/stop 315",
                                          from: %{first_name: "Carlo", id: 233328, last_name: "Colombo",
                                                  username: "carlo_colombo"}, id: "100222753899",
                                          message: %{chat: %{first_name: "Carlo", id: 2334, last_name: "Colombo",
                                                             type: "private", username: "cal_cmbo"}, date: 1490222776,
                                                     entities: [%{length: 20, offset: 0, type: "bold"},
                                                                %{length: 71, offset: 21, type: "pre"}],
                                                     from: %{first_name: "Dublin Bus", id: 371, username: "testDBbot"},
                                                     message_id: 1009,
                                                     text: "315 - Bachelors Walk\n  25B | Due\n  66B | 1 Mins\n  39A | 3 Mins\n   39 | 7 Mins\n   66 | 8 Mins"}},
                        chosen_inline_result: nil, edited_message: nil, inline_query: nil,
                        message: nil, update_id: 83609457}

    {:ok, _} = TestAPI3.entry_point(msg)
  end
  defp make_message(text), do: %{message: %{
                                    chat: %{
                                      id: 42 },
                                    text: text }}
end
