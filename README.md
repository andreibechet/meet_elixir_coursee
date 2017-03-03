# Streamers

The task: parse M3U8 Video Streaming Files. HTTP video streams are managed by several text files. There is an index file that lists the available bitrates. Each bitrate has a text file that lists hundreds of video files that can be streamed to a client. The app will find the index file, than build the list of available video files for each bitrate.

This app is developed during the Pluralsight Meet Elixir course with Jose Valim.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `streamers` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [{:streamers, "~> 0.1.0"}]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/streamers](https://hexdocs.pm/streamers).

