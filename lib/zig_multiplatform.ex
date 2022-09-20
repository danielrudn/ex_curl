defmodule ExCurl.Zig.MultiPlatform do
  @moduledoc false
  defmacro __using__(zig_opts) do
    platform = :os.type()

    found =
      Keyword.get(zig_opts, :platform_opts, [])
      |> Enum.map(fn {_, _, value} -> value end)
      |> Enum.map(&Enum.into(&1, %{}))
      |> Enum.find(&(&1[:platform] == platform))

    opts =
      case found do
        value when is_map(value) -> Keyword.merge(zig_opts, value[:options])
        _ -> zig_opts
      end

    quote do
      use Zig, unquote(opts)
    end
  end
end
