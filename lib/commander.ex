defmodule Commander do
  require Logger

  defmacro __using__(_options) do
    quote do
      import unquote(__MODULE__)
      require Logger

      Module.register_attribute(__MODULE__, :commands, accumulate: true)

      @before_compile unquote(__MODULE__)
    end
  end

  defmacro command("/"<>cmd, args, desc \\  nil) do
    quote do
      @commands %{
        command: unquote(cmd),
        args: unquote(args),
        description: unquote(desc),
        commands_module: @module,
        entry_point: @handler
      }
    end
  end

  defmacro not_found([do: body]) do
    %Macro.Env{module: module} = __CALLER__
    Module.put_attribute(module, :error_handler, body)
  end

  defmacro dispatch(params, [do: body]) do
    quote do
      @module        unquote(Keyword.get(params, :to))
      @handler       unquote(Keyword.get(params, :handler, :entry_point))

      unquote(body)
    end
  end

  defmacro __before_compile__(%Macro.Env{module: module}) do
    commands = Module.get_attribute(module, :commands)

    [define_handler(commands |> hd)] ++
      Enum.map(commands, &define_dispatch/1) ++
      [define_catch_all_dispatch]
  end

  defp define_dispatch(%{command: cmd, args: args, commands_module: module}) do
    Logger.debug("#{module} /#{cmd} #{inspect(args)}")
    fn_name = String.to_atom(cmd)
    case length(args) do
      0 -> quote do
          defp __dispatch(chat_id, unquote("/#{cmd} ") <> _) do
            raise "too much argument"
          end
          defp __dispatch(chat_id, unquote("/#{cmd}")) do
            apply(unquote(module), unquote(fn_name), [chat_id])
          end
        end
      1 -> quote do
          defp __dispatch(chat_id, unquote("/#{cmd} ") <> arg) do
            apply(unquote(module), unquote(fn_name), [chat_id, String.strip(arg)])
          end
          defp __dispatch(chat_id, unquote("/#{cmd}")) do
            raise "too few arguments"
          end
        end
      _ -> quote do
          defp __dispatch(chat_id, unquote("/#{cmd} ") <> args = command) do
            splitted = String.split(args)
            if length(splitted) == unquote(length(args)) do
              apply(unquote(module), unquote(fn_name), [chat_id | splitted])
            else
              raise "invalid number of arguments"
            end
          end
        end
    end
  end

  defp define_catch_all_dispatch()do
    quote do
      defp __dispatch(chat_id, text), do: {:ok, text}
    end
  end

  defp define_handler(%{entry_point: handler}) do
    quote do
      defp __rescue(chat_id, error, text) do
        Logger.error(inspect(error))
        Logger.error(inspect(text))
        {:error, error}
      end

      defp __handler(chat_id, text) do
        Logger.info("Dispatching '#{text}'")
        try do
          __dispatch(chat_id, text |> String.strip)
        rescue
          e -> __rescue(chat_id, e, text)
        end
      end
      def unquote(handler)(%{"message" => %{"chat" => %{"id" => chat_id}, "text" => text }} ) do
        __handler(chat_id, text)
      end
      def unquote(handler)(%{message: %{chat: %{id: chat_id}, text: text }} ) do
        __handler(chat_id, text)
      end
      def unquote(handler)(payload) do
        Logger.error "Invalid payload"
        inspect(payload)
        |> Logger.error
      end
    end
  end
end
