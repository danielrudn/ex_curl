defmodule ExCurl.Zig.MultiPlatformCurl do
  @moduledoc false

  @load_order [
    %{
      name: :debian,
      lib: "/usr/lib/x86_64-linux-gnu/libcurl.so",
      include: "/usr/include/x86_64-linux-gnu/curl"
    },
    %{name: :arch, lib: "/usr/lib/libcurl.so", include: "/usr/include/curl"},
    %{
      name: :macos,
      lib: "/usr/local/opt/curl/lib/libcurl.dylib",
      include: "/usr/local/opt/curl/include/curl"
    }
  ]

  defmacro __using__(_opts) do
    %{lib: lib, include: include} =
      Enum.find(@load_order, &(File.exists?(&1[:lib]) && File.exists?(&1[:include])))

    quote do
      use Zig, libs: [unquote(lib)], include: [unquote(include)], link_libc: true
    end
  end
end
