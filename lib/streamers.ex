defmodule Streamers do
  @moduledoc """
  Documentation for Streamers.
  """

  require Record
  Record.defrecord :m3u8, [program_id: nil, path: nil, bandwidth: nil]

  @doc """
  Find streaming index file in the given directory.

  ## Examples
    iex> Streamers.find_index("this/doesnt/exist")
    nil
  """
  def find_index(directory) do
    files = Path.join(directory, "*.m3u8")
    if file = Enum.find(Path.wildcard(files), fn(file) -> is_index?(file) end) do # can also be written is_index?(&1)
      file
    end
  end

  def is_index?(file) do
    File.open!(file,
      fn(pid) -> IO.read(pid, 25) == "#EXTM3U\n#EXT-X-STREAM-INF" end)
  end

  def extract_m3u8(index_file) do
    []
    File.open!(index_file,
      fn(pid) ->
        IO.read(pid, :line)
        do_extract_m3u8(pid, Path.dirname(index_file), [])
      end)
  end

  defp do_extract_m3u8(pid, dir, acc) do
    case IO.read(pid, :line) do
      :eof -> Enum.reverse(acc)
      stream_inf ->
        path = IO.read(pid, :line)
        do_extract_m3u8(pid, dir, stream_inf, path, acc)
    end
  end

  defp do_extract_m3u8(pid, dir, stream_inf, path, acc) do
    # expecting #EXT-X-STREAM-INF:PROGRAM-ID=1,BANDWIDTH=110000
    << "#EXT-X-STREAM-INF:PROGRAM-ID=", program_id, ",BANDWIDTH=", bandwidth :: binary >> = stream_inf
    # program_id is 1 char; the bandwidth is marked as binary since we don't know how many bits are left

    path = Path.join(dir, path |> String.strip)
    bandwidth = bandwidth |> String.strip |> String.to_integer
    record = m3u8(program_id: program_id - ?0, path: path, bandwidth: bandwidth )
    # do the - ?0 in order to convert it from ascii to actual int value (ascii start at 48)
    do_extract_m3u8(pid, dir, [record | acc])
  end

end
