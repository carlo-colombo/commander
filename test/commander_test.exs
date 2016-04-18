defmodule CommanderTest do
  use ExUnit.Case
  doctest Commander

  def unwatch(_), do: {:unwatch}
  def stop(_, args), do: {:stop, args}
  def watch(_, arg1, arg2), do: {:watch, arg1, arg2}
  def error_handler(_,_,_), do: :error_handler

  defmodule TestAPI2 do
    use Commander

    dispatch to: CommanderTest, handler: :entry_point do
      command "/unwatch", []
      command "/watch", [:stop, :line]
      command "/stop", [:stop]
    end
  end

  defmodule TestAPI3 do
    use Commander

    dispatch to: CommanderTest, handler: :entry_point  do
      command "/unwatch", []
      command "/stop", [:stop]
      command "/watch", [:stop, :line]

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

  defp make_message(text), do: %{message: %{
                                 chat: %{
                                   id: 42 },
                                 text: text }}
end
